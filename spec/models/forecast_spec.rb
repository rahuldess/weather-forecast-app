require 'rails_helper'

RSpec.describe Forecast, type: :model do
  let(:forecast_attributes) do
    {
      current_temperature: 72,
      temperature_unit: 'F',
      high_temperature: 80,
      low_temperature: 60,
      current_conditions: 'Sunny',
      detailed_forecast: 'Sunny skies throughout the day',
      extended_forecast: [
        { name: 'Today', temperature: 80, short_forecast: 'Sunny' },
        { name: 'Tonight', temperature: 60, short_forecast: 'Clear' }
      ],
      from_cache: false,
      cached_at: Time.current,
      zip_code: '20500',
      formatted_address: '1600 Pennsylvania Avenue NW, Washington, DC 20500, USA'
    }
  end

  describe '#initialize' do
    it 'sets all attributes correctly' do
      forecast = described_class.new(forecast_attributes)

      expect(forecast.current_temperature).to eq(72)
      expect(forecast.temperature_unit).to eq('F')
      expect(forecast.high_temperature).to eq(80)
      expect(forecast.low_temperature).to eq(60)
      expect(forecast.current_conditions).to eq('Sunny')
      expect(forecast.detailed_forecast).to eq('Sunny skies throughout the day')
      expect(forecast.extended_forecast.length).to eq(2)
      expect(forecast.from_cache).to be false
      expect(forecast.zip_code).to eq('20500')
      expect(forecast.formatted_address).to eq('1600 Pennsylvania Avenue NW, Washington, DC 20500, USA')
    end

    it 'sets default values for optional attributes' do
      minimal_forecast = described_class.new(current_temperature: 65)

      expect(minimal_forecast.temperature_unit).to eq('F')
      expect(minimal_forecast.extended_forecast).to eq([])
      expect(minimal_forecast.from_cache).to be false
    end

    it 'handles nil values gracefully' do
      forecast = described_class.new(
        current_temperature: nil,
        high_temperature: nil,
        low_temperature: nil
      )

      expect(forecast.current_temperature).to be_nil
      expect(forecast.high_temperature).to be_nil
      expect(forecast.low_temperature).to be_nil
    end
  end

  describe '#from_cache?' do
    it 'returns true when from_cache is true' do
      forecast = described_class.new(forecast_attributes.merge(from_cache: true))
      expect(forecast.from_cache?).to be true
    end

    it 'returns false when from_cache is false' do
      forecast = described_class.new(forecast_attributes.merge(from_cache: false))
      expect(forecast.from_cache?).to be false
    end
  end

  describe '#cache_status' do
    it 'returns cached status when from cache' do
      cached_time = Time.current
      forecast = described_class.new(forecast_attributes.merge(from_cache: true, cached_at: cached_time))

      expect(forecast.cache_status).to include('Cached')
      expect(forecast.cache_status).to include(cached_time.strftime('%I:%M %p'))
    end

    it 'returns fresh data status when not from cache' do
      forecast = described_class.new(forecast_attributes.merge(from_cache: false))

      expect(forecast.cache_status).to eq('Fresh Data')
    end
  end

  describe '#current_temp_display' do
    it 'formats current temperature with unit' do
      forecast = described_class.new(forecast_attributes)
      expect(forecast.current_temp_display).to eq('72°F')
    end
  end

  describe '#high_temp_display' do
    it 'formats high temperature with unit' do
      forecast = described_class.new(forecast_attributes)
      expect(forecast.high_temp_display).to eq('80°F')
    end

    it 'returns N/A when high temperature is nil' do
      forecast = described_class.new(forecast_attributes.merge(high_temperature: nil))
      expect(forecast.high_temp_display).to eq('N/A')
    end
  end

  describe '#low_temp_display' do
    it 'formats low temperature with unit' do
      forecast = described_class.new(forecast_attributes)
      expect(forecast.low_temp_display).to eq('60°F')
    end

    it 'returns N/A when low temperature is nil' do
      forecast = described_class.new(forecast_attributes.merge(low_temperature: nil))
      expect(forecast.low_temp_display).to eq('N/A')
    end
  end

  describe '#formatted_cache_time' do
    it 'formats cached_at time correctly' do
      cached_time = Time.zone.local(2026, 2, 6, 14, 30, 0)
      forecast = described_class.new(forecast_attributes.merge(cached_at: cached_time))

      expect(forecast.formatted_cache_time).to eq('02:30 PM on February 06, 2026')
    end

    it 'returns empty string when cached_at is nil' do
      forecast = described_class.new(forecast_attributes.merge(cached_at: nil))

      expect(forecast.formatted_cache_time).to eq('')
    end
  end

  describe 'temperature units' do
    it 'supports Celsius temperature unit' do
      forecast = described_class.new(
        current_temperature: 22,
        temperature_unit: 'C',
        high_temperature: 25,
        low_temperature: 18
      )

      expect(forecast.current_temp_display).to eq('22°C')
      expect(forecast.high_temp_display).to eq('25°C')
      expect(forecast.low_temp_display).to eq('18°C')
    end
  end

  describe 'extended forecast' do
    it 'handles empty extended forecast array' do
      forecast = described_class.new(forecast_attributes.merge(extended_forecast: []))

      expect(forecast.extended_forecast).to eq([])
      expect(forecast.extended_forecast).to be_an(Array)
    end

    it 'preserves extended forecast data structure' do
      forecast = described_class.new(forecast_attributes)

      expect(forecast.extended_forecast.first[:name]).to eq('Today')
      expect(forecast.extended_forecast.first[:temperature]).to eq(80)
      expect(forecast.extended_forecast.first[:short_forecast]).to eq('Sunny')
    end
  end

  describe 'attribute readers' do
    it 'provides read access to all attributes' do
      forecast = described_class.new(forecast_attributes)

      expect(forecast).to respond_to(:current_temperature)
      expect(forecast).to respond_to(:temperature_unit)
      expect(forecast).to respond_to(:high_temperature)
      expect(forecast).to respond_to(:low_temperature)
      expect(forecast).to respond_to(:current_conditions)
      expect(forecast).to respond_to(:detailed_forecast)
      expect(forecast).to respond_to(:extended_forecast)
      expect(forecast).to respond_to(:from_cache)
      expect(forecast).to respond_to(:cached_at)
      expect(forecast).to respond_to(:zip_code)
      expect(forecast).to respond_to(:formatted_address)
    end

    it 'does not allow attribute modification' do
      forecast = described_class.new(forecast_attributes)

      expect(forecast).not_to respond_to(:current_temperature=)
      expect(forecast).not_to respond_to(:temperature_unit=)
    end
  end

  describe '.from_service_results' do
    let(:geocoding_result) do
      {
        latitude: 40.7128,
        longitude: -74.0060,
        zip_code: '10001',
        formatted_address: 'New York, NY 10001, USA'
      }
    end

    let(:weather_result) do
      {
        current_temperature: 68,
        temperature_unit: 'F',
        high_temperature: 75,
        low_temperature: 58,
        current_conditions: 'Partly cloudy',
        detailed_forecast: 'Partly cloudy throughout the day',
        extended_forecast: [
          { name: 'Today', temperature: 80, short_forecast: 'Sunny' }
        ],
        from_cache: false,
        cached_at: Time.current
      }
    end

    it 'creates a forecast from service results' do
      forecast = described_class.from_service_results(geocoding_result, weather_result)

      expect(forecast).to be_a(described_class)
      expect(forecast.current_temperature).to eq(68)
      expect(forecast.zip_code).to eq('10001')
      expect(forecast.formatted_address).to eq('New York, NY 10001, USA')
    end

    it 'merges geocoding and weather data' do
      forecast = described_class.from_service_results(geocoding_result, weather_result)

      expect(forecast.current_temperature).to eq(68)
      expect(forecast.high_temperature).to eq(75)
      expect(forecast.low_temperature).to eq(58)
      expect(forecast.zip_code).to eq('10001')
      expect(forecast.formatted_address).to eq('New York, NY 10001, USA')
    end

    it 'preserves extended forecast data' do
      forecast = described_class.from_service_results(geocoding_result, weather_result)

      expect(forecast.extended_forecast.length).to eq(1)
      expect(forecast.extended_forecast.first[:name]).to eq('Today')
    end

    it 'handles cached weather data' do
      cached_weather = weather_result.merge(from_cache: true, cached_at: Time.current)
      forecast = described_class.from_service_results(geocoding_result, cached_weather)

      expect(forecast.from_cache?).to be true
      expect(forecast.cached_at).not_to be_nil
    end

    it 'only includes relevant keys from service results' do
      extra_geocoding = geocoding_result.merge(extra_key: 'should not be included')
      extra_weather = weather_result.merge(another_key: 'also should not be included')

      forecast = described_class.from_service_results(extra_geocoding, extra_weather)

      expect(forecast).not_to respond_to(:extra_key)
      expect(forecast).not_to respond_to(:another_key)
    end
  end

  describe 'edge cases and validations' do
    it 'handles missing detailed_forecast' do
      forecast = described_class.new(forecast_attributes.merge(detailed_forecast: nil))

      expect(forecast.detailed_forecast).to be_nil
    end

    it 'handles missing current_conditions' do
      forecast = described_class.new(forecast_attributes.merge(current_conditions: nil))

      expect(forecast.current_conditions).to be_nil
    end

    it 'handles very long formatted addresses' do
      long_address = 'A' * 500
      forecast = described_class.new(forecast_attributes.merge(formatted_address: long_address))

      expect(forecast.formatted_address).to eq(long_address)
    end

    it 'handles extreme temperature values' do
      forecast = described_class.new(
        current_temperature: -50,
        high_temperature: 150,
        low_temperature: -60,
        temperature_unit: 'F'
      )

      expect(forecast.current_temp_display).to eq('-50°F')
      expect(forecast.high_temp_display).to eq('150°F')
      expect(forecast.low_temp_display).to eq('-60°F')
    end
  end
end
