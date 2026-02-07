require 'rails_helper'

RSpec.describe GeocodingService, type: :service do
  include_context 'geocoder mocks'

  describe '#call' do
    context 'with a valid address' do
      it 'returns success with geocoded data' do
        allow(Geocoder).to receive(:search).with('1600 Pennsylvania Avenue NW, Washington, DC')
                                           .and_return([valid_geocoder_result])

        result = described_class.new('1600 Pennsylvania Avenue NW, Washington, DC').call

        expect(result[:success]).to be true
        expect(result[:latitude]).to eq(38.8977)
        expect(result[:longitude]).to eq(-77.0365)
        expect(result[:zip_code]).to eq('20500')
        expect(result[:formatted_address]).to eq('1600 Pennsylvania Avenue NW, Washington, DC 20500, USA')
      end
    end

    context 'with a blank address' do
      it 'returns an error' do
        result = described_class.new('').call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.geocoding.blank_address'))
      end
    end

    context 'with an invalid address' do
      it 'returns an error when address is not found' do
        allow(Geocoder).to receive(:search).with('Invalid Address XYZ123').and_return([])

        result = described_class.new('Invalid Address XYZ123').call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.geocoding.not_found'))
      end
    end

    context 'when geocoding fails' do
      it 'returns an error message' do
        allow(Geocoder).to receive(:search).and_raise(StandardError.new('Network error'))

        result = described_class.new('Some Address').call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.geocoding.failed'))
      end
    end

    context 'with partial geocoding results' do
      it 'handles missing postal code' do
        geocoder_result = double(
          latitude: 40.7128,
          longitude: -74.0060,
          postal_code: nil,
          address: 'New York, NY, USA',
          data: { 'address' => {} }
        )
        allow(Geocoder).to receive(:search).and_return([geocoder_result])

        result = described_class.new('New York, NY').call

        expect(result[:success]).to be true
        expect(result[:zip_code]).to eq('unknown')
      end

      it 'handles missing formatted address' do
        geocoder_result = double(
          latitude: 40.7128,
          longitude: -74.0060,
          postal_code: '10001',
          address: nil,
          data: { 'address' => {} }
        )
        allow(Geocoder).to receive(:search).and_return([geocoder_result])

        result = described_class.new('New York, NY').call

        expect(result[:success]).to be true
        expect(result[:formatted_address]).to be_nil
      end
    end

    context 'with various address formats' do
      it 'handles city and state only' do
        geocoder_result = double(
          latitude: 47.6062,
          longitude: -122.3321,
          postal_code: '98101',
          address: 'Seattle, WA 98101, USA',
          data: {}
        )
        allow(Geocoder).to receive(:search).with('Seattle, WA').and_return([geocoder_result])

        result = described_class.new('Seattle, WA').call

        expect(result[:success]).to be true
        expect(result[:latitude]).to eq(47.6062)
        expect(result[:longitude]).to eq(-122.3321)
      end

      it 'handles full street address' do
        geocoder_result = double(
          latitude: 37.7749,
          longitude: -122.4194,
          postal_code: '94102',
          address: '1 Market St, San Francisco, CA 94102, USA',
          data: {}
        )
        allow(Geocoder).to receive(:search).with('1 Market St, San Francisco, CA').and_return([geocoder_result])

        result = described_class.new('1 Market St, San Francisco, CA').call

        expect(result[:success]).to be true
        expect(result[:zip_code]).to eq('94102')
      end

      it 'handles zip code only' do
        geocoder_result = double(
          latitude: 90_210,
          longitude: -118.4065,
          postal_code: '90210',
          address: 'Beverly Hills, CA 90210, USA',
          data: {}
        )
        allow(Geocoder).to receive(:search).with('90210').and_return([geocoder_result])

        result = described_class.new('90210').call

        expect(result[:success]).to be true
        expect(result[:zip_code]).to eq('90210')
      end
    end

    describe '#extract_zip_code private method' do
      it 'extracts zip code from postal_code attribute' do
        geocoder_result = double(postal_code: '10001', data: {})
        service = described_class.new('test')

        zip = service.send(:extract_zip_code, geocoder_result)

        expect(zip).to eq('10001')
      end

      it 'returns unknown when postal_code is missing' do
        geocoder_result = double(postal_code: nil, data: { 'address' => {} })
        service = described_class.new('test')

        zip = service.send(:extract_zip_code, geocoder_result)

        expect(zip).to eq('unknown')
      end
    end

    context 'with edge cases' do
      it 'handles whitespace-only address' do
        result = described_class.new('   ').call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.geocoding.blank_address'))
      end

      it 'handles very long addresses' do
        long_address = 'A' * 500
        allow(Geocoder).to receive(:search).with(long_address).and_return([])

        result = described_class.new(long_address).call

        expect(result[:success]).to be false
        expect(result[:error]).to eq(I18n.t('errors.geocoding.not_found'))
      end

      it 'handles special characters in address' do
        address = '123 Main St #456, City, ST'
        geocoder_result = double(
          latitude: 40.0,
          longitude: -74.0,
          postal_code: '12345',
          address: address,
          data: {}
        )
        allow(Geocoder).to receive(:search).with(address).and_return([geocoder_result])

        result = described_class.new(address).call

        expect(result[:success]).to be true
      end
    end

    context 'with multiple geocoding results' do
      it 'uses the first result when multiple are returned' do
        first_result = double(
          latitude: 40.7128,
          longitude: -74.0060,
          postal_code: '10001',
          address: 'New York, NY 10001, USA',
          data: {}
        )
        second_result = double(
          latitude: 41.0,
          longitude: -75.0,
          postal_code: '10002',
          address: 'Different Location',
          data: {}
        )
        allow(Geocoder).to receive(:search).and_return([first_result, second_result])

        result = described_class.new('New York').call

        expect(result[:success]).to be true
        expect(result[:latitude]).to eq(40.7128)
        expect(result[:zip_code]).to eq('10001')
      end
    end
  end
end
