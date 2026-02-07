require 'rails_helper'

RSpec.describe TimezoneService do
  include_context 'timezone mocks'

  describe '#call' do
    context 'with localhost IP addresses' do
      %w[127.0.0.1 ::1 192.168.1.1 10.0.0.1].each do |ip|
        it "returns UTC for #{ip}" do
          result = described_class.new(ip).call

          expect(result[:success]).to be true
          expect(result[:timezone]).to eq('UTC')
        end
      end
    end

    context 'with public IP addresses' do
      it 'returns timezone information from geocoder' do
        allow(Geocoder).to receive(:search).and_return([sf_timezone_result])

        result = described_class.new('8.8.8.8').call

        expect(result[:success]).to be true
        expect(result[:timezone]).to eq('America/Los_Angeles')
        expect(result[:city]).to eq('San Francisco')
        expect(result[:state]).to eq('California')
        expect(result[:country]).to eq('United States')
        expect(result[:country_code]).to eq('US')
      end

      it 'falls back to coordinate-based timezone when timezone data is missing' do
        allow(Geocoder).to receive(:search).and_return([ny_timezone_result])

        result = described_class.new('8.8.8.8').call

        expect(result[:success]).to be true
        expect(result[:timezone]).to eq('America/New_York')
      end
    end

    context 'when geocoder returns no results' do
      it 'returns default UTC timezone' do
        allow(Geocoder).to receive(:search).and_return([])

        result = described_class.new('8.8.8.8').call

        expect(result[:success]).to be true
        expect(result[:timezone]).to eq('UTC')
        expect(result[:city]).to be_nil
      end
    end

    context 'when geocoder raises an error' do
      it 'returns default UTC timezone and logs error' do
        allow(Geocoder).to receive(:search).and_raise(StandardError.new('API error'))
        allow(Rails.logger).to receive(:error)

        result = described_class.new('8.8.8.8').call

        expect(result[:success]).to be true
        expect(result[:timezone]).to eq('UTC')
        expect(Rails.logger).to have_received(:error).with(/Timezone geocoding failed/)
      end
    end

    context 'timezone estimation from coordinates' do
      [
        { mock: :boston_timezone_result, expected: 'America/New_York', name: 'Eastern' },
        { mock: :chicago_timezone_result, expected: 'America/Chicago', name: 'Central' },
        { mock: :denver_timezone_result, expected: 'America/Denver', name: 'Mountain' },
        { mock: :seattle_timezone_result, expected: 'America/Los_Angeles', name: 'Pacific' }
      ].each do |test_case|
        it "estimates #{test_case[:name]} timezone" do
          allow(Geocoder).to receive(:search).and_return([send(test_case[:mock])])

          result = described_class.new('8.8.8.8').call

          expect(result[:timezone]).to eq(test_case[:expected])
        end
      end
    end
  end
end
