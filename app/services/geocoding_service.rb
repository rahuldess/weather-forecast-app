class GeocodingService < BaseService
  class GeocodingError < StandardError; end

  UNKNOWN_ZIP_CODE = 'unknown'.freeze

  # Retry configuration for geocoding API
  RETRY_OPTIONS = {
    tries: 3,
    base_interval: 0.5,
    max_interval: 2,
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
      Rails.logger.warn "Geocoding API retry #{try}/3 after #{elapsed_time}s due to #{exception.class}: #{exception.message}. Next retry in #{next_interval}s"
    }
  }.freeze

  def initialize(address)
    @address = address
  end

  def call
    return error_result(I18n.t('errors.geocoding.blank_address')) if @address.blank?

    # Check if circuit breaker is open
    if circuit_open?
      Rails.logger.warn 'Geocoding API circuit breaker is OPEN'
      return error_result(I18n.t('errors.geocoding.service_unavailable'))
    end

    # Fetch with circuit breaker and retry logic
    fetch_with_circuit_breaker
  rescue Timeout::Error, Net::OpenTimeout, Net::ReadTimeout => e
    Rails.logger.error "Geocoding timeout error: #{e.message}\n#{e.backtrace.join("\n")}"
    error_result(I18n.t('errors.geocoding.timeout'))
  rescue StandardError => e
    Rails.logger.error "Geocoding failed: #{e.message}\n#{e.backtrace.join("\n")}"
    error_result(I18n.t('errors.geocoding.failed'))
  end

  private

  def circuit_open?
    GEOCODING_API_CIRCUIT.open?
  end

  def fetch_with_circuit_breaker
    GEOCODING_API_CIRCUIT.run do
      fetch_with_retry
    end
  rescue Circuitbox::OpenCircuitError
    Rails.logger.error 'Geocoding API circuit breaker is OPEN - too many failures'
    error_result(I18n.t('errors.geocoding.service_unavailable'))
  end

  def fetch_with_retry
    Retriable.retriable(RETRY_OPTIONS) do
      perform_geocoding
    end
  end

  def perform_geocoding
    geocoded = Geocoder.search(@address).first

    return error_result(I18n.t('errors.geocoding.not_found')) if geocoded.nil?

    success_result(
      latitude: geocoded.latitude,
      longitude: geocoded.longitude,
      zip_code: extract_zip_code(geocoded),
      formatted_address: geocoded.address
    )
  end

  def extract_zip_code(geocoded)
    geocoded.postal_code || geocoded.data.dig('address', 'postcode') || UNKNOWN_ZIP_CODE
  end
end
