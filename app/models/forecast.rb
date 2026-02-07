class Forecast
  include TemperatureFormattable

  DEFAULT_TEMPERATURE_UNIT = 'F'.freeze
  DEFAULT_EXTENDED_FORECAST = [].freeze
  DEFAULT_FROM_CACHE = false
  CACHE_STATUS_FRESH = 'Fresh Data'.freeze
  CACHE_TIME_FORMAT = '%I:%M %p on %B %d, %Y'.freeze

  attr_reader :current_temperature, :temperature_unit, :high_temperature,
              :low_temperature, :current_conditions, :detailed_forecast,
              :extended_forecast, :from_cache, :cached_at, :zip_code,
              :formatted_address

  def self.from_service_results(geocoding_result, weather_result)
    new(
      weather_result.slice(
        :current_temperature, :temperature_unit, :high_temperature,
        :low_temperature, :current_conditions, :detailed_forecast,
        :extended_forecast, :from_cache, :cached_at
      ).merge(
        geocoding_result.slice(:zip_code, :formatted_address)
      )
    )
  end

  def initialize(attributes = {})
    @current_temperature = attributes[:current_temperature]
    @temperature_unit = attributes[:temperature_unit] || DEFAULT_TEMPERATURE_UNIT
    @high_temperature = attributes[:high_temperature]
    @low_temperature = attributes[:low_temperature]
    @current_conditions = attributes[:current_conditions]
    @detailed_forecast = attributes[:detailed_forecast]
    @extended_forecast = attributes[:extended_forecast] || DEFAULT_EXTENDED_FORECAST
    @from_cache = attributes[:from_cache] || DEFAULT_FROM_CACHE
    @cached_at = attributes[:cached_at]
    @zip_code = attributes[:zip_code]
    @formatted_address = attributes[:formatted_address]
  end

  def cache_status
    from_cache? ? "Cached (Retrieved at #{formatted_cache_time})" : CACHE_STATUS_FRESH
  end

  def from_cache?
    @from_cache
  end

  def formatted_cache_time
    return '' unless @cached_at

    @cached_at.strftime(CACHE_TIME_FORMAT)
  end

  # Dynamically define temperature display methods
  %i[current high low].each do |temp_type|
    define_method("#{temp_type}_temp_display") do
      format_temperature(send("#{temp_type}_temperature"), temperature_unit)
    end
  end
end
