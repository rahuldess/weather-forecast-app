# frozen_string_literal: true

class WeatherService < BaseService
  include HTTParty

  base_uri 'https://api.open-meteo.com'

  # Separate connection and read timeouts for better control
  default_options.update(
    open_timeout: 2,  # Time to establish connection
    read_timeout: 5   # Time to read response
  )

  CACHE_EXPIRATION = ENV.fetch('WEATHER_CACHE_EXPIRATION', 30).to_i.minutes
  TEMPERATURE_UNIT = 'F'
  CACHE_KEY_PREFIX = 'weather_forecast_'
  NOT_AVAILABLE = 'N/A'
  WIND_SPEED_PRECISION = 1

  # Retry configuration
  RETRY_OPTIONS = {
    tries: 3,
    base_interval: 0.5,
    max_interval: 2,
    multiplier: 2,
    on: [
      Net::OpenTimeout,
      Net::ReadTimeout,
      Timeout::Error,
      Errno::ECONNREFUSED,
      Errno::ETIMEDOUT,
      SocketError
    ],
    on_retry: proc { |exception, try, elapsed_time, next_interval|
      Rails.logger.warn "Weather API retry #{try}/3 after #{elapsed_time}s due to #{exception.class}: #{exception.message}. Next retry in #{next_interval}s"
    }
  }.freeze

  def initialize(latitude, longitude, zip_code)
    @latitude = validate_coordinate(latitude, -90, 90, 'latitude')
    @longitude = validate_coordinate(longitude, -180, 180, 'longitude')
    @zip_code = zip_code
  end

  def call
    ActiveSupport::Notifications.instrument('weather_service.fetch', zip_code: @zip_code) do
      # First, try to get cached data
      cached_data = fetch_from_cache

      # If circuit is open, return cached data or error
      if circuit_open?
        Rails.logger.warn 'Weather API circuit breaker is OPEN, using cached data or returning error'
        return cached_data || error_result(I18n.t('errors.weather.service_unavailable'))
      end

      # Return cached data if available
      return cached_data if cached_data

      # Fetch from API with circuit breaker protection
      fetch_with_circuit_breaker
    end
  rescue HTTParty::Error, Net::OpenTimeout, Net::ReadTimeout, Timeout::Error => e
    Rails.logger.error "Weather API network error: #{e.message}\n#{e.backtrace.join("\n")}"
    # Try to return stale cache as fallback
    fetch_from_cache(allow_stale: true) || error_result(I18n.t('errors.weather.api_error'))
  rescue JSON::ParserError => e
    Rails.logger.error "Weather API parsing error: #{e.message}\n#{e.backtrace.join("\n")}"
    error_result(I18n.t('errors.weather.parse_error'))
  rescue StandardError => e
    Rails.logger.error "Weather service unexpected error: #{e.message}\n#{e.backtrace.join("\n")}"
    # Try to return stale cache as fallback
    fetch_from_cache(allow_stale: true) || error_result(I18n.t('errors.weather.api_error'))
  end

  private

  def circuit_open?
    WEATHER_API_CIRCUIT.open?
  end

  def fetch_with_circuit_breaker
    WEATHER_API_CIRCUIT.run do
      fetch_from_api_with_retry
    end
  rescue Circuitbox::OpenCircuitError
    Rails.logger.error 'Weather API circuit breaker is OPEN - too many failures'
    # Return stale cache if available
    fetch_from_cache(allow_stale: true) || error_result(I18n.t('errors.weather.service_unavailable'))
  end

  def fetch_from_api_with_retry
    Retriable.retriable(RETRY_OPTIONS) do
      fetch_from_api
    end
  end

  def fetch_from_cache(allow_stale: false)
    cached = Rails.cache.read(cache_key)
    return nil unless cached

    # Check if cache is stale (older than expiration time)
    if !allow_stale && cached[:timestamp]
      cache_age = Time.current - cached[:timestamp]
      return nil if cache_age > CACHE_EXPIRATION
    end

    cached.merge(
      from_cache: true,
      cached_at: cached[:timestamp],
      stale: allow_stale && cached[:timestamp] && (Time.current - cached[:timestamp] > CACHE_EXPIRATION)
    )
  end

  def fetch_from_api
    response = self.class.get('/v1/forecast', query: api_query_params)

    # Differentiate between client errors (4xx) and server errors (5xx)
    if response.code >= 500
      # Server errors are retryable
      Rails.logger.error "Weather API server error (#{response.code}): #{response.message}"
      raise HTTParty::Error, "Server error: #{response.code}"
    elsif response.code >= 400
      # Client errors are not retryable
      Rails.logger.error "Weather API client error (#{response.code}): #{response.message}"
      return error_result(I18n.t('errors.weather.invalid_request'))
    elsif !response.success?
      Rails.logger.error "Weather API unexpected status (#{response.code}): #{response.message}"
      return error_result(I18n.t('errors.weather.fetch_failed'))
    end

    return error_result(I18n.t('errors.weather.invalid_response')) unless valid_response?(response)

    result = parse_forecast_data(response)
    cache_result(result)
    result.merge(from_cache: false)
  end

  def api_query_params
    Weather::ApiConfig.query_params_for(@latitude, @longitude)
  end

  def parse_forecast_data(response)
    current = response['current'] || {}
    daily = response['daily'] || {}

    current_data = extract_current_data(current)
    temperature_data = extract_temperature_data(current, daily)

    success_result(
      current_temperature: current_data[:temperature],
      temperature_unit: TEMPERATURE_UNIT,
      high_temperature: temperature_data[:high],
      low_temperature: temperature_data[:low],
      current_conditions: current_data[:conditions],
      detailed_forecast: build_detailed_forecast(current_data, temperature_data),
      extended_forecast: Weather::ForecastBuilder.build_extended_forecast(daily),
      feels_like: current_data[:feels_like],
      humidity: current_data[:humidity],
      wind_speed: current_data[:wind_speed],
      timestamp: Time.current
    )
  end

  def extract_current_data(current)
    weather_code = current['weather_code'] || Weather::Codes::DEFAULT_WEATHER_CODE

    {
      temperature: current['temperature_2m']&.round || NOT_AVAILABLE,
      feels_like: current['apparent_temperature']&.round,
      conditions: Weather::Codes.description_for(weather_code),
      humidity: current['relative_humidity_2m'],
      wind_speed: current['wind_speed_10m']&.round(WIND_SPEED_PRECISION)
    }
  end

  def extract_temperature_data(_current, daily)
    {
      high: daily['temperature_2m_max']&.first&.round || NOT_AVAILABLE,
      low: daily['temperature_2m_min']&.first&.round || NOT_AVAILABLE
    }
  end

  def build_detailed_forecast(current_data, temperature_data)
    Weather::ForecastBuilder.build_detailed_forecast(
      current_data[:conditions],
      temperature_data[:high],
      temperature_data[:low],
      current_data[:humidity],
      current_data[:wind_speed]
    )
  end

  def cache_result(result)
    Rails.cache.write(cache_key, result, expires_in: CACHE_EXPIRATION)
  end

  def cache_key
    "#{CACHE_KEY_PREFIX}#{@zip_code}"
  end

  def validate_coordinate(value, min, max, name)
    numeric_value = Float(value)
    unless numeric_value.between?(min, max)
      raise ArgumentError, "Invalid #{name}: #{value}. Must be between #{min} and #{max}"
    end

    numeric_value
  rescue ArgumentError, TypeError
    raise ArgumentError, "Invalid #{name}: #{value}. Must be a valid number"
  end

  def valid_response?(response)
    response.parsed_response.is_a?(Hash) &&
      response['current'].present? &&
      response['daily'].present?
  end

  def error_result(message)
    super.merge(from_cache: false)
  end
end
