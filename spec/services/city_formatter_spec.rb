require 'rails_helper'

RSpec.describe CityFormatter do
  describe '.format' do
    context 'with US addresses' do
      it 'formats US city with state' do
        geocoder_result = double(
          city: 'New York',
          state: 'NY',
          country_code: 'US',
          country: 'United States'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('New York, NY')
      end

      it 'formats US city with full state name' do
        geocoder_result = double(
          city: 'Seattle',
          state: 'Washington',
          country_code: 'US',
          country: 'United States'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Seattle, Washington')
      end

      it 'falls back to city and country when state is missing' do
        geocoder_result = double(
          city: 'Washington',
          state: nil,
          country_code: 'US',
          country: 'United States'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Washington, United States')
      end
    end

    context 'with international addresses' do
      it 'formats international city with country' do
        geocoder_result = double(
          city: 'London',
          state: nil,
          country_code: 'GB',
          country: 'United Kingdom'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('London, United Kingdom')
      end

      it 'formats Canadian city with province and country' do
        geocoder_result = double(
          city: 'Toronto',
          state: 'Ontario',
          country_code: 'CA',
          country: 'Canada'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Toronto, Canada')
      end

      it 'formats French city with country' do
        geocoder_result = double(
          city: 'Paris',
          state: 'Île-de-France',
          country_code: 'FR',
          country: 'France'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Paris, France')
      end
    end

    context 'with edge cases' do
      it 'returns nil when geocoder_result is nil' do
        result = described_class.format(nil)

        expect(result).to be_nil
      end

      it 'returns nil when city is nil' do
        geocoder_result = double(
          city: nil,
          state: 'NY',
          country_code: 'US',
          country: 'United States'
        )

        result = described_class.format(geocoder_result)

        expect(result).to be_nil
      end

      it 'returns city only when country is missing' do
        geocoder_result = double(
          city: 'Unknown City',
          state: nil,
          country_code: nil,
          country: nil
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Unknown City')
      end

      it 'handles empty strings for state and country' do
        geocoder_result = double(
          city: 'Test City',
          state: '',
          country_code: '',
          country: ''
        )

        result = described_class.format(geocoder_result)

        # Empty strings are truthy, so it will format as "Test City, "
        expect(result).to eq('Test City, ')
      end
    end

    context 'with various US cities' do
      it 'formats Los Angeles correctly' do
        geocoder_result = double(
          city: 'Los Angeles',
          state: 'CA',
          country_code: 'US',
          country: 'United States'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Los Angeles, CA')
      end

      it 'formats Miami correctly' do
        geocoder_result = double(
          city: 'Miami',
          state: 'FL',
          country_code: 'US',
          country: 'United States'
        )

        result = described_class.format(geocoder_result)

        expect(result).to eq('Miami, FL')
      end
    end

    context 'with geocoder result object' do
      it 'works with actual geocoder result structure' do
        # Using a Struct instead of OpenStruct to avoid dependency
        GeocoderResult = Struct.new(:city, :state, :country_code, :country)
        geocoder_result = GeocoderResult.new('Chicago', 'IL', 'US', 'United States')

        result = described_class.format(geocoder_result)

        expect(result).to eq('Chicago, IL')
      end
    end
  end
end
