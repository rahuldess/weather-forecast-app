# frozen_string_literal: true

module Weather
  # Builds forecast data structures from raw weather API responses
  # Handles both detailed current forecasts and extended multi-day forecasts
  class ForecastBuilder
    TEMPERATURE_UNIT = 'F'
    NOT_AVAILABLE = 'N/A'
    TODAY_LABEL = 'Today'
    DATE_FORMAT = '%B %d'
    DAY_FORMAT = '%A'
    UNKNOWN_CONDITIONS = 'Unknown conditions'

    class << self
      def build_detailed_forecast(conditions, high, low, humidity, wind_speed)
        parts = [conditions]
        parts << temperature_range_text(high, low) if valid_temperature_range?(high, low)
        parts << humidity_text(humidity) if humidity
        parts << wind_speed_text(wind_speed) if wind_speed

        format_forecast_parts(parts)
      end

      def build_daily_forecast(conditions, high, low, precip_prob)
        parts = [conditions || UNKNOWN_CONDITIONS]
        parts << daily_temperature_text(high, low) if high && low
        parts << precipitation_text(precip_prob) if should_include_precipitation?(precip_prob)

        format_forecast_parts(parts)
      end

      # Transforms daily weather API data into an array of structured forecast entries
      # Extracts time series data (dates, temps, weather codes, precipitation) and builds
      # individual daily forecast hashes with formatted information
      def build_extended_forecast(daily)
        return [] unless valid_daily_data?(daily)

        daily_data = extract_daily_data(daily)
        build_forecast_entries(daily_data)
      end

      private

      def valid_daily_data?(daily)
        daily&.dig('time')&.any?
      end

      def extract_daily_data(daily)
        {
          dates: daily['time'],
          max_temps: daily['temperature_2m_max'],
          min_temps: daily['temperature_2m_min'],
          weather_codes: daily['weather_code'],
          precipitation_prob: daily['precipitation_probability_max']
        }
      end

      # Maps each date to a daily entry by extracting corresponding data at each index
      def build_forecast_entries(daily_data)
        daily_data[:dates].each_with_index.map do |date, index|
          build_daily_entry(
            date: date,
            index: index,
            max_temp: daily_data[:max_temps][index],
            min_temp: daily_data[:min_temps][index],
            weather_code: daily_data[:weather_codes][index],
            precip_prob: daily_data[:precipitation_prob][index]
          )
        end.compact
      end

      def build_daily_entry(date:, index:, max_temp:, min_temp:, weather_code:, precip_prob:) # rubocop:disable Metrics/ParameterLists
        date_obj = parse_date(date)
        return nil unless date_obj

        {
          name: format_day_name(date_obj, index),
          date: format_date(date_obj),
          temperature: max_temp&.round,
          temperature_min: min_temp&.round,
          temperature_unit: TEMPERATURE_UNIT,
          short_forecast: Weather::Codes.description_for(weather_code),
          detailed_forecast: build_daily_forecast(
            Weather::Codes.description_for(weather_code),
            max_temp,
            min_temp,
            precip_prob
          ),
          precipitation_probability: precip_prob
        }
      end

      def parse_date(date_string)
        Date.parse(date_string)
      rescue ArgumentError => e
        Rails.logger.error("Failed to parse date '#{date_string}': #{e.message}")
        nil
      end

      def format_day_name(date_obj, index)
        index.zero? ? TODAY_LABEL : date_obj.strftime(DAY_FORMAT)
      end

      def format_date(date_obj)
        date_obj.strftime(DATE_FORMAT)
      end

      def valid_temperature_range?(high, low)
        high != NOT_AVAILABLE && low != NOT_AVAILABLE
      end

      def temperature_range_text(high, low)
        "High of #{high}°#{TEMPERATURE_UNIT} and low of #{low}°#{TEMPERATURE_UNIT}"
      end

      def daily_temperature_text(high, low)
        "High: #{high.round}°#{TEMPERATURE_UNIT}, Low: #{low.round}°#{TEMPERATURE_UNIT}"
      end

      def humidity_text(humidity)
        "Humidity: #{humidity}%"
      end

      def wind_speed_text(wind_speed)
        "Wind speed: #{wind_speed} mph"
      end

      def precipitation_text(precip_prob)
        "Precipitation: #{precip_prob}%"
      end

      def should_include_precipitation?(precip_prob)
        precip_prob&.positive?
      end

      def format_forecast_parts(parts)
        "#{parts.join('. ')}."
      end
    end
  end
end
