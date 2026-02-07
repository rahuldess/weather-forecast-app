require 'rails_helper'

RSpec.describe ForecastRetriever, type: :service do
  describe '#call' do
    let(:address) { 'New York, NY' }
    let(:geocoding_success) do
      {
        success: true,
        latitude: 40.7128,
        longitude: -74.0060,
        zip_code: '10001',
        formatted_address: 'New York, NY 10001, USA'
      }
    end
    let(:weather_success) do
      {
        success: true,
        current_temperature: 68,
        temperature_unit: 'F',
        high_temperature: 75,
        low_temperature: 58,
        current_conditions: 'Partly cloudy',
        detailed_forecast: 'Partly cloudy. High of 75°F and low of 58°F.',
        extended_forecast: []
      }
    end

    context 'with a blank address' do
      it 'returns an error result' do
        result = described_class.new('').call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.forecast.address_required'))
      end

      it 'returns an error for nil address' do
        result = described_class.new(nil).call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.forecast.address_required'))
      end
    end

    context 'with a valid address' do
      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success)
        allow_any_instance_of(WeatherService).to receive(:call).and_return(weather_success)
      end

      it 'returns success with forecast data' do
        result = described_class.new(address).call

        expect(result[:success]).to be true
        expect(result[:forecast]).to be_a(Forecast)
      end

      it 'creates a forecast with correct attributes' do
        result = described_class.new(address).call

        forecast = result[:forecast]
        expect(forecast.current_temperature).to eq(68)
        expect(forecast.zip_code).to eq('10001')
        expect(forecast.formatted_address).to eq('New York, NY 10001, USA')
      end

      it 'calls GeocodingService with the address' do
        geocoding_service = instance_double(GeocodingService)
        allow(GeocodingService).to receive(:new).with(address).and_return(geocoding_service)
        allow(geocoding_service).to receive(:call).and_return(geocoding_success)
        allow_any_instance_of(WeatherService).to receive(:call).and_return(weather_success)

        described_class.new(address).call

        expect(GeocodingService).to have_received(:new).with(address)
        expect(geocoding_service).to have_received(:call)
      end

      it 'calls WeatherService with geocoded coordinates' do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success)
        weather_service = instance_double(WeatherService)
        allow(WeatherService).to receive(:new).with(40.7128, -74.0060, '10001').and_return(weather_service)
        allow(weather_service).to receive(:call).and_return(weather_success)

        described_class.new(address).call

        expect(WeatherService).to have_received(:new).with(40.7128, -74.0060, '10001')
        expect(weather_service).to have_received(:call)
      end
    end

    context 'when geocoding fails' do
      let(:geocoding_error) do
        {
          success: false,
          error: 'Address not found. Please enter a valid US address.'
        }
      end

      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_error)
      end

      it 'returns the geocoding error result' do
        result = described_class.new(address).call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Address not found. Please enter a valid US address.')
      end

      it 'does not call WeatherService' do
        weather_service = instance_double(WeatherService)
        allow(WeatherService).to receive(:new).and_return(weather_service)
        allow(weather_service).to receive(:call)

        described_class.new(address).call

        expect(WeatherService).not_to have_received(:new)
      end
    end

    context 'when weather service fails' do
      let(:weather_error) do
        {
          success: false,
          error: 'Unable to fetch weather data for this location'
        }
      end

      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success)
        allow_any_instance_of(WeatherService).to receive(:call).and_return(weather_error)
      end

      it 'returns the weather service error result' do
        result = described_class.new(address).call

        expect(result[:success]).to be false
        expect(result[:error]).to eq('Unable to fetch weather data for this location')
      end

      it 'does not create a forecast' do
        result = described_class.new(address).call

        expect(result[:forecast]).to be_nil
      end
    end

    context 'integration with real service flow' do
      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success)
        allow_any_instance_of(WeatherService).to receive(:call).and_return(weather_success)
      end

      it 'successfully orchestrates the full forecast retrieval process' do
        result = described_class.new('Seattle, WA').call

        expect(result[:success]).to be true
        expect(result[:forecast]).to be_a(Forecast)
        expect(result[:forecast].current_temperature).to eq(68)
        expect(result[:forecast].current_conditions).to eq('Partly cloudy')
      end
    end
  end
end
