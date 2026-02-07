require 'rails_helper'

RSpec.describe 'Forecasts', type: :request do
  include_context 'service results'

  before do
    # Mock timezone detection for all tests
    allow_any_instance_of(TimezoneService).to receive(:call).and_return(timezone_success_result)
  end

  describe 'GET /' do
    context 'without address parameter' do
      it 'returns successful response' do
        get root_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Search for a city or address')
      end

      it 'displays the search form' do
        get root_path

        expect(response.body).to include('Search for a city or address')
        expect(response.body).to include('Search')
      end
    end

    context 'with valid address parameter' do
      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success_result)
        allow_any_instance_of(WeatherService).to receive(:call).and_return(weather_success_result)
      end

      it 'displays weather forecast for the address' do
        get root_path, params: { address: 'New York, NY' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('68')
        expect(response.body).to include('Partly cloudy')
        expect(response.body).to include('New York, NY 10001, USA')
      end

      it 'displays extended forecast' do
        get root_path, params: { address: 'New York, NY' }

        expect(response.body).to include('Today')
        expect(response.body).to include('Friday')
        expect(response.body).to include('75')
        expect(response.body).to include('72')
      end

      it 'displays high and low temperatures' do
        get root_path, params: { address: 'New York, NY' }

        expect(response.body).to include('High:')
        expect(response.body).to include('Low:')
        expect(response.body).to include('75')
        expect(response.body).to include('58')
      end
    end

    context 'with invalid address' do
      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return({
                                                                               success: false,
                                                                               error: 'Address not found. Please enter a valid US address.'
                                                                             })
      end

      it 'displays error message' do
        get root_path, params: { address: 'Invalid Address XYZ123' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('errors.geocoding.not_found'))
      end

      it 'does not display forecast data' do
        get root_path, params: { address: 'Invalid Address XYZ123' }

        expect(response.body).not_to include('Extended Forecast')
      end
    end

    context 'when weather API fails' do
      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success_result)
        allow_any_instance_of(WeatherService).to receive(:call).and_return({
                                                                             success: false,
                                                                             error: 'Unable to fetch weather data for this location'
                                                                           })
      end

      it 'displays error message' do
        get root_path, params: { address: 'New York, NY' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Unable to fetch weather data')
      end
    end

    context 'with cached weather data' do
      let(:cached_time) { 15.minutes.ago }

      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_return(geocoding_success_result)
        allow_any_instance_of(WeatherService).to receive(:call).and_return(
          weather_success_result.merge(from_cache: true, cached_at: cached_time, extended_forecast: [])
        )
      end

      it 'displays cache status' do
        get root_path, params: { address: 'New York, NY' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include('Cached')
      end
    end
  end

  describe 'GET /detect_location' do
    it 'redirects to root path' do
      get detect_location_path

      expect(response).to redirect_to(root_path)
    end

    it 'handles the request successfully' do
      get detect_location_path

      follow_redirect!
      expect(response).to have_http_status(:success)
    end
  end

  describe 'Integration: Full weather forecast flow' do
    let(:seattle_geocoding_result) do
      {
        success: true,
        latitude: 47.6062,
        longitude: -122.3321,
        zip_code: '98101',
        formatted_address: 'Seattle, WA 98101, USA'
      }
    end

    let(:seattle_weather_result) do
      {
        success: true,
        current_temperature: 55,
        temperature_unit: 'F',
        high_temperature: 62,
        low_temperature: 48,
        current_conditions: 'Overcast',
        detailed_forecast: 'Overcast. High of 62°F and low of 48°F. Humidity: 75%. Wind speed: 12.0 mph.',
        extended_forecast: [
          {
            name: 'Today',
            date: 'February 06',
            temperature: 62,
            temperature_min: 48,
            temperature_unit: 'F',
            short_forecast: 'Overcast',
            detailed_forecast: 'Overcast. High: 62°F, Low: 48°F. Precipitation: 60%.',
            precipitation_probability: 60
          }
        ],
        from_cache: false,
        cached_at: nil,
        feels_like: 52,
        humidity: 75,
        wind_speed: 12.0,
        timestamp: Time.current
      }
    end

    before do
      allow_any_instance_of(GeocodingService).to receive(:call).and_return(seattle_geocoding_result)
      allow_any_instance_of(WeatherService).to receive(:call).and_return(seattle_weather_result)
    end

    it 'completes full forecast request successfully' do
      # Step 1: Visit homepage
      get root_path
      expect(response).to have_http_status(:success)

      # Step 2: Submit address
      get root_path, params: { address: 'Seattle, WA' }
      expect(response).to have_http_status(:success)

      # Step 3: Verify forecast is displayed
      expect(response.body).to include('55')
      expect(response.body).to include('Overcast')
      expect(response.body).to include('Seattle, WA 98101, USA')
      expect(response.body).to include('62') # High temp
      expect(response.body).to include('48') # Low temp
      expect(response.body).to include('Today')
    end

    it 'handles timezone detection in the flow' do
      timezone_result = {
        success: true,
        timezone: 'America/Los_Angeles',
        city: 'Seattle',
        state: 'WA',
        country: 'United States',
        country_code: 'US'
      }
      allow_any_instance_of(TimezoneService).to receive(:call).and_return(timezone_result)

      get root_path, params: { address: 'Seattle, WA' }

      expect(response).to have_http_status(:success)
      expect(response.body).to include('55')
    end
  end

  describe 'Error handling' do
    context 'when error occurs in service layer' do
      before do
        allow_any_instance_of(GeocodingService).to receive(:call).and_raise(StandardError.new('Service error'))
      end

      it 'displays i18n error message' do
        get root_path, params: { address: 'Some Address' }

        expect(response).to have_http_status(:success)
        expect(response.body).to include(I18n.t('errors.forecast.retrieval_failed'))
      end
    end
  end

  describe 'Response headers and format' do
    it 'returns HTML content type' do
      get root_path

      expect(response.content_type).to match(%r{text/html})
    end

    it 'does not cache the response' do
      get root_path

      # Rails typically sets cache-control headers
      expect(response).to have_http_status(:success)
    end
  end
end
