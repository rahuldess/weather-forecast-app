class TimezoneService < BaseService
  include IpHelper

  class TimezoneError < StandardError; end

  # Constants
  DEFAULT_TIMEZONE = 'UTC'.freeze
  TIMEZONE_EASTERN = 'America/New_York'.freeze
  TIMEZONE_CENTRAL = 'America/Chicago'.freeze
  TIMEZONE_MOUNTAIN = 'America/Denver'.freeze
  TIMEZONE_PACIFIC = 'America/Los_Angeles'.freeze

  # Longitude boundaries for US timezones
  LONGITUDE_EASTERN_BOUNDARY = -75
  LONGITUDE_CENTRAL_BOUNDARY = -90
  LONGITUDE_MOUNTAIN_BOUNDARY = -115
  LONGITUDE_PACIFIC_BOUNDARY = -130

  # Retry configuration for timezone/IP geolocation API
  RETRY_OPTIONS = {
    tries: 2, # Fewer retries for timezone since it's not critical
    base_interval: 0.5,
    max_interval: 1,
    multiplier: 2,
    on: [
      Timeout::Error,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Errno::ECONNREFUSED,
      Errno::ETIMEDOUT,
      SocketError
    ],
    on_retry: proc { |exception, try, elapsed_time, next_interval|
      Rails.logger.warn "Timezone API retry #{try}/2 after #{elapsed_time}s due to #{exception.class}: #{exception.message}. Next retry in #{next_interval}s"
    }
  }.freeze

  def initialize(ip_address)
    @ip_address = ip_address
  end

  def call
    return default_timezone if localhost_or_private?(@ip_address)

    # Check if circuit breaker is open
    if circuit_open?
      Rails.logger.warn 'Timezone API circuit breaker is OPEN, using default timezone'
      return default_timezone
    end

    # Fetch with circuit breaker and retry logic
    fetch_with_circuit_breaker
  rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.warn "Timezone API timeout: #{e.message}"
    default_timezone
  rescue StandardError => e
    Rails.logger.error "Timezone geocoding failed: #{e.message}\n#{e.backtrace.join("\n")}"
    default_timezone
  end

  private

  def circuit_open?
    TIMEZONE_API_CIRCUIT.open?
  end

  def fetch_with_circuit_breaker
    TIMEZONE_API_CIRCUIT.run do
      fetch_with_retry
    end
  rescue Circuitbox::OpenCircuitError
    Rails.logger.warn 'Timezone API circuit breaker is OPEN - using default timezone'
    default_timezone
  end

  def fetch_with_retry
    Retriable.retriable(RETRY_OPTIONS) do
      perform_timezone_lookup
    end
  end

  def perform_timezone_lookup
    result = Geocoder.search(@ip_address).first

    if result
      # Try to get timezone from the geocoder result
      timezone = extract_timezone(result)

      success_result(
        timezone: timezone,
        city: result.city,
        state: result.state,
        country: result.country,
        country_code: result.country_code
      )
    else
      default_timezone
    end
  end

  def extract_timezone(result)
    # Different geocoding providers return timezone in different formats
    timezone = result.data['timezone'] ||
               result.data.dig('location', 'time_zone', 'name') ||
               result.data['time_zone']

    # Validate the timezone
    if timezone && ActiveSupport::TimeZone[timezone]
      timezone
    else
      # Fallback: try to determine timezone from coordinates
      timezone_from_coordinates(result.latitude, result.longitude)
    end
  end

  def timezone_from_coordinates(_lat, lon)
    # Simple timezone estimation based on longitude
    # This is a rough approximation - for production, consider using a dedicated timezone API

    # Map common US timezones based on rough longitude ranges
    if lon > LONGITUDE_EASTERN_BOUNDARY # Eastern
      TIMEZONE_EASTERN
    elsif lon > LONGITUDE_CENTRAL_BOUNDARY  # Central
      TIMEZONE_CENTRAL
    elsif lon > LONGITUDE_MOUNTAIN_BOUNDARY # Mountain
      TIMEZONE_MOUNTAIN
    elsif lon > LONGITUDE_PACIFIC_BOUNDARY # Pacific
      TIMEZONE_PACIFIC
    else
      DEFAULT_TIMEZONE
    end
  end

  def default_timezone
    success_result(
      timezone: DEFAULT_TIMEZONE,
      city: nil,
      state: nil,
      country: nil,
      country_code: nil
    )
  end
end
