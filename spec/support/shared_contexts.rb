# Shared contexts for RSpec tests
RSpec.shared_context 'geocoder mocks' do
  let(:valid_geocoder_result) do
    double(
      'Geocoder::Result',
      latitude: 38.8977,
      longitude: -77.0365,
      postal_code: '20500',
      address: '1600 Pennsylvania Avenue NW, Washington, DC 20500, USA',
      data: { 'address' => { 'postcode' => '20500' } }
    )
  end

  let(:ny_geocoder_result) do
    double(
      'Geocoder::Result',
      latitude: 40.7128,
      longitude: -74.0060,
      postal_code: '10001',
      address: 'New York, NY 10001, USA',
      data: { 'address' => { 'postcode' => '10001' } }
    )
  end

  let(:seattle_geocoder_result) do
    double(
      'Geocoder::Result',
      latitude: 47.6062,
      longitude: -122.3321,
      postal_code: '98101',
      address: 'Seattle, WA 98101, USA',
      data: { 'address' => { 'postcode' => '98101' } }
    )
  end
end

RSpec.shared_context 'timezone mocks' do
  let(:sf_timezone_result) do
    double(
      'GeocoderResult',
      city: 'San Francisco',
      state: 'California',
      country: 'United States',
      country_code: 'US',
      latitude: 37.7749,
      longitude: -122.4194,
      data: { 'timezone' => 'America/Los_Angeles' }
    )
  end

  let(:ny_timezone_result) do
    double(
      'GeocoderResult',
      city: 'New York',
      state: 'New York',
      country: 'United States',
      country_code: 'US',
      latitude: 40.7128,
      longitude: -74.0060,
      data: {}
    )
  end

  let(:chicago_timezone_result) do
    double(
      'GeocoderResult',
      city: 'Chicago',
      state: 'IL',
      country: 'United States',
      country_code: 'US',
      latitude: 41.8781,
      longitude: -87.6298,
      data: {}
    )
  end

  let(:denver_timezone_result) do
    double(
      'GeocoderResult',
      city: 'Denver',
      state: 'CO',
      country: 'United States',
      country_code: 'US',
      latitude: 39.7392,
      longitude: -104.9903,
      data: {}
    )
  end

  let(:seattle_timezone_result) do
    double(
      'GeocoderResult',
      city: 'Seattle',
      state: 'WA',
      country: 'United States',
      country_code: 'US',
      latitude: 47.6062,
      longitude: -122.3321,
      data: {}
    )
  end

  let(:boston_timezone_result) do
    double(
      'GeocoderResult',
      city: 'Boston',
      state: 'MA',
      country: 'United States',
      country_code: 'US',
      latitude: 42.3601,
      longitude: -71.0589,
      data: {}
    )
  end
end

RSpec.shared_context 'weather mocks' do
  let(:open_meteo_success_response) do
    {
      'current' => {
        'temperature_2m' => 72.5,
        'apparent_temperature' => 70.2,
        'relative_humidity_2m' => 65,
        'weather_code' => 0,
        'wind_speed_10m' => 8.5
      },
      'daily' => {
        'time' => %w[
          2026-02-05
          2026-02-06
          2026-02-07
          2026-02-08
          2026-02-09
          2026-02-10
          2026-02-11
        ],
        'temperature_2m_max' => [75.2, 73.4, 71.6, 69.8, 72.5, 74.3, 76.1],
        'temperature_2m_min' => [55.4, 54.7, 53.6, 52.3, 54.1, 55.8, 57.2],
        'weather_code' => [0, 1, 2, 3, 61, 0, 1],
        'precipitation_sum' => [0, 0, 0, 0, 0.5, 0, 0],
        'precipitation_probability_max' => [0, 10, 20, 30, 80, 5, 15]
      }
    }
  end

  let(:open_meteo_rain_response) do
    {
      'current' => {
        'temperature_2m' => 65.0,
        'apparent_temperature' => 63.0,
        'relative_humidity_2m' => 70,
        'weather_code' => 61,
        'wind_speed_10m' => 10.0
      },
      'daily' => {
        'time' => ['2026-02-05'],
        'temperature_2m_max' => [68.0],
        'temperature_2m_min' => [58.0],
        'weather_code' => [61],
        'precipitation_sum' => [0.2],
        'precipitation_probability_max' => [70]
      }
    }
  end
end

RSpec.shared_context 'service results' do
  let(:geocoding_success_result) do
    {
      success: true,
      latitude: 40.7128,
      longitude: -74.0060,
      zip_code: '10001',
      formatted_address: 'New York, NY 10001, USA'
    }
  end

  let(:weather_success_result) do
    {
      success: true,
      current_temperature: 68,
      temperature_unit: 'F',
      high_temperature: 75,
      low_temperature: 58,
      current_conditions: 'Partly cloudy',
      detailed_forecast: 'Partly cloudy. High of 75°F and low of 58°F. Humidity: 60%. Wind speed: 10.0 mph.',
      extended_forecast: [
        {
          name: 'Today',
          date: 'February 06',
          temperature: 75,
          temperature_min: 58,
          temperature_unit: 'F',
          short_forecast: 'Partly cloudy',
          detailed_forecast: 'Partly cloudy. High: 75°F, Low: 58°F. Precipitation: 20%.',
          precipitation_probability: 20
        },
        {
          name: 'Friday',
          date: 'February 07',
          temperature: 72,
          temperature_min: 55,
          temperature_unit: 'F',
          short_forecast: 'Clear sky',
          detailed_forecast: 'Clear sky. High: 72°F, Low: 55°F.',
          precipitation_probability: 0
        }
      ],
      from_cache: false,
      cached_at: nil,
      feels_like: 66,
      humidity: 60,
      wind_speed: 10.0,
      timestamp: Time.current
    }
  end

  let(:timezone_success_result) do
    {
      success: true,
      timezone: 'UTC',
      city: nil,
      state: nil,
      country: nil,
      country_code: nil
    }
  end
end
