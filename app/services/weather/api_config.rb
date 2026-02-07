# frozen_string_literal: true

module Weather
  module ApiConfig
    API_QUERY_PARAMS = {
      current: 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      daily: 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
      temperature_unit: 'fahrenheit',
      wind_speed_unit: 'mph',
      precipitation_unit: 'inch',
      timezone: 'auto',
      forecast_days: 7
    }.freeze

    def self.query_params_for(latitude, longitude)
      API_QUERY_PARAMS.merge(
        latitude: latitude,
        longitude: longitude
      )
    end
  end
end
