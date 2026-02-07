require 'rails_helper'

RSpec.describe WeatherService, type: :service do
  include_context 'weather mocks'

  let(:latitude) { 38.8977 }
  let(:longitude) { -77.0365 }
  let(:zip_code) { '20500' }
  let(:invalid_latitude) { 100 }
  let(:invalid_longitude) { 200 }
  let(:query_params) do
    {
      'latitude' => latitude.to_s,
      'longitude' => longitude.to_s,
      'current' => 'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
      'daily' => 'weather_code,temperature_2m_max,temperature_2m_min,precipitation_sum,precipitation_probability_max',
      'temperature_unit' => 'fahrenheit',
      'wind_speed_unit' => 'mph',
      'precipitation_unit' => 'inch',
      'timezone' => 'auto',
      'forecast_days' => '7'
    }
  end

  before do
    Rails.cache.clear
  end

  describe '#call' do
    context 'when fetching fresh data from API' do
      it 'returns weather data and caches it' do
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: open_meteo_success_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:success]).to be true
        expect(result[:current_temperature]).to eq(73) # rounded from 72.5
        expect(result[:temperature_unit]).to eq('F')
        expect(result[:high_temperature]).to eq(75) # rounded from 75.2
        expect(result[:low_temperature]).to eq(55) # rounded from 55.4
        expect(result[:current_conditions]).to eq('Clear sky')
        expect(result[:feels_like]).to eq(70) # rounded from 70.2
        expect(result[:humidity]).to eq(65)
        expect(result[:wind_speed]).to eq(8.5)
        expect(result[:from_cache]).to be false
        expect(result[:extended_forecast]).to be_an(Array)
        expect(result[:extended_forecast].length).to eq(7)

        # Check first day of extended forecast
        first_day = result[:extended_forecast].first
        expect(first_day[:name]).to eq('Today')
        expect(first_day[:temperature]).to eq(75)
        expect(first_day[:temperature_min]).to eq(55)
        expect(first_day[:short_forecast]).to eq('Clear sky')
        expect(first_day[:precipitation_probability]).to eq(0)
      end
    end

    context 'when data is cached' do
      it 'returns cached data' do
        timestamp = 10.minutes.ago
        cached_data = {
          current_temperature: 70,
          temperature_unit: 'F',
          high_temperature: 75,
          low_temperature: 55,
          current_conditions: 'Partly cloudy',
          detailed_forecast: 'Partly cloudy. High of 75°F and low of 55°F. Humidity: 60%. Wind speed: 5.0 mph.',
          extended_forecast: [],
          feels_like: 68,
          humidity: 60,
          wind_speed: 5.0,
          timestamp: timestamp
        }

        Rails.cache.write("weather_forecast_#{zip_code}", cached_data, expires_in: 30.minutes)

        service = described_class.new(latitude, longitude, zip_code)
        result = service.call

        expect(result[:current_temperature]).to eq(70)
        expect(result[:from_cache]).to be true
        expect(result[:cached_at]).to eq(timestamp)
      end
    end

    context 'when API request fails' do
      it 'returns an error' do
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_return(status: 500, body: 'Internal Server Error')

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:success]).to be false
        expect(result[:error]).to include('trouble getting weather data')
      end
    end

    context 'when parsing weather codes' do
      it 'correctly interprets WMO weather codes' do
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: open_meteo_rain_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:current_conditions]).to eq('Slight rain')
      end
    end

    context 'when API returns invalid response structure' do
      it 'returns an error for missing current data' do
        invalid_response = { 'daily' => {} }
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: invalid_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:success]).to be false
        expect(result[:error]).to include('invalid weather data')
      end

      it 'returns an error for missing daily data' do
        invalid_response = { 'current' => {} }
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: invalid_response.to_json, headers: { 'Content-Type' => 'application/json' })

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:success]).to be false
        expect(result[:error]).to include('invalid weather data')
      end
    end

    context 'when API request times out' do
      it 'returns a timeout error' do
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_timeout

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:success]).to be false
        expect(result[:error]).to include('trouble getting weather data')
      end
    end

    context 'when response is not valid JSON' do
      it 'returns a parse error' do
        stub_request(:get, 'https://api.open-meteo.com/v1/forecast')
          .with(query: hash_including(query_params))
          .to_return(status: 200, body: 'Invalid JSON{', headers: { 'Content-Type' => 'application/json' })

        result = described_class.new(latitude, longitude, zip_code).call

        expect(result[:success]).to be false
        expect(result[:error]).to include('Unable to process weather data')
      end
    end
  end

  describe '#initialize' do
    context 'with valid coordinates' do
      it 'creates a service instance' do
        expect { described_class.new(latitude, longitude, zip_code) }.not_to raise_error
      end
    end

    context 'with invalid latitude' do
      it 'raises an ArgumentError' do
        expect { described_class.new(invalid_latitude, longitude, zip_code) }
          .to raise_error(ArgumentError, /Invalid latitude/)
      end

      it 'raises an ArgumentError for non-numeric latitude' do
        expect { described_class.new('invalid', longitude, zip_code) }
          .to raise_error(ArgumentError, /Invalid latitude/)
      end
    end

    context 'with invalid longitude' do
      it 'raises an ArgumentError' do
        expect { described_class.new(latitude, invalid_longitude, zip_code) }
          .to raise_error(ArgumentError, /Invalid longitude/)
      end

      it 'raises an ArgumentError for non-numeric longitude' do
        expect { described_class.new(latitude, 'invalid', zip_code) }
          .to raise_error(ArgumentError, /Invalid longitude/)
      end
    end
  end
end
