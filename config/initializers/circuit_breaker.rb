# frozen_string_literal: true

# Circuit Breaker Configuration
# Protects the application from cascading failures when external services are down

require 'circuitbox'

# Configure Circuitbox to use Rails cache
Circuitbox.configure do |config|
  config.default_circuit_store = Circuitbox::MemoryStore.new
end

# Circuit breaker for Weather API
WEATHER_API_CIRCUIT = Circuitbox.circuit(:weather_api, {
  # Number of requests in window before checking error threshold
  volume_threshold: 5,
  
  # Percentage of errors that will trip the circuit (50%)
  error_threshold: 50,
  
  # Time window for counting errors (60 seconds)
  time_window: 60,
  
  # Time to wait before attempting to close the circuit (30 seconds)
  sleep_window: 30,
  
  # Exceptions that should be counted as failures
  exceptions: [
    HTTParty::Error,
    Net::OpenTimeout,
    Net::ReadTimeout,
    Timeout::Error,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    SocketError
  ]
})

# Circuit breaker for Geocoding API
GEOCODING_API_CIRCUIT = Circuitbox.circuit(:geocoding_api, {
  volume_threshold: 5,
  error_threshold: 50,
  time_window: 60,
  sleep_window: 30,
  exceptions: [
    Geocoder::Error,
    Timeout::Error,
    Net::OpenTimeout,
    Net::ReadTimeout,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    SocketError
  ]
})

# Circuit breaker for Timezone/IP Geolocation API
TIMEZONE_API_CIRCUIT = Circuitbox.circuit(:timezone_api, {
  volume_threshold: 5,
  error_threshold: 50,
  time_window: 60,
  sleep_window: 30,
  exceptions: [
    Geocoder::Error,
    Timeout::Error,
    Net::OpenTimeout,
    Net::ReadTimeout,
    Errno::ECONNREFUSED,
    Errno::ETIMEDOUT,
    SocketError
  ]
})
