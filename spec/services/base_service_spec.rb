require 'rails_helper'

RSpec.describe BaseService, type: :service do
  # Create a test class that inherits from BaseService
  let(:test_service_class) do
    Class.new(BaseService) do
      def call
        # Test implementation
      end
    end
  end

  let(:service_instance) { test_service_class.new }

  describe '#success_result' do
    it 'returns a hash with success true' do
      result = service_instance.send(:success_result)

      expect(result[:success]).to be true
    end

    it 'returns a hash with provided data' do
      data = { temperature: 72, conditions: 'Sunny' }
      result = service_instance.send(:success_result, data)

      expect(result[:success]).to be true
      expect(result[:temperature]).to eq(72)
      expect(result[:conditions]).to eq('Sunny')
    end

    it 'merges data into the result hash' do
      data = { latitude: 40.7128, longitude: -74.0060, city: 'New York' }
      result = service_instance.send(:success_result, data)

      expect(result[:success]).to be true
      expect(result[:latitude]).to eq(40.7128)
      expect(result[:longitude]).to eq(-74.0060)
      expect(result[:city]).to eq('New York')
    end

    it 'returns only success true when no data is provided' do
      result = service_instance.send(:success_result)

      expect(result.keys).to eq([:success])
      expect(result[:success]).to be true
    end

    it 'handles empty hash as data' do
      result = service_instance.send(:success_result, {})

      expect(result[:success]).to be true
      expect(result.keys).to eq([:success])
    end

    it 'preserves all data keys' do
      data = {
        forecast: 'Sunny',
        temperature: 75,
        humidity: 60,
        wind_speed: 10
      }
      result = service_instance.send(:success_result, data)

      expect(result[:success]).to be true
      expect(result[:forecast]).to eq('Sunny')
      expect(result[:temperature]).to eq(75)
      expect(result[:humidity]).to eq(60)
      expect(result[:wind_speed]).to eq(10)
    end
  end

  describe '#error_result' do
    it 'returns a hash with success false' do
      result = service_instance.send(:error_result, 'An error occurred')

      expect(result[:success]).to be false
    end

    it 'returns a hash with the error message' do
      error_message = 'Unable to fetch data'
      result = service_instance.send(:error_result, error_message)

      expect(result[:success]).to be false
      expect(result[:error]).to eq(error_message)
    end

    it 'handles different error messages' do
      messages = [
        'Address not found',
        'Network timeout',
        'Invalid API key',
        'Service unavailable'
      ]

      messages.each do |message|
        result = service_instance.send(:error_result, message)

        expect(result[:success]).to be false
        expect(result[:error]).to eq(message)
      end
    end

    it 'returns only success and error keys' do
      result = service_instance.send(:error_result, 'Test error')

      expect(result.keys.sort).to eq(%i[error success])
    end

    it 'handles empty string as error message' do
      result = service_instance.send(:error_result, '')

      expect(result[:success]).to be false
      expect(result[:error]).to eq('')
    end

    it 'handles long error messages' do
      long_message = 'A' * 500
      result = service_instance.send(:error_result, long_message)

      expect(result[:success]).to be false
      expect(result[:error]).to eq(long_message)
    end
  end

  describe 'inheritance' do
    it 'allows subclasses to use success_result' do
      subclass = Class.new(BaseService) do
        def call
          success_result(data: 'test')
        end
      end

      result = subclass.new.call

      expect(result[:success]).to be true
      expect(result[:data]).to eq('test')
    end

    it 'allows subclasses to use error_result' do
      subclass = Class.new(BaseService) do
        def call
          error_result('test error')
        end
      end

      result = subclass.new.call

      expect(result[:success]).to be false
      expect(result[:error]).to eq('test error')
    end
  end

  describe 'real-world usage patterns' do
    it 'supports conditional success/error results' do
      conditional_service = Class.new(BaseService) do
        def initialize(should_succeed)
          @should_succeed = should_succeed
        end

        def call
          if @should_succeed
            success_result(message: 'Operation completed')
          else
            error_result('Operation failed')
          end
        end
      end

      success_result = conditional_service.new(true).call
      expect(success_result[:success]).to be true
      expect(success_result[:message]).to eq('Operation completed')

      error_result = conditional_service.new(false).call
      expect(error_result[:success]).to be false
      expect(error_result[:error]).to eq('Operation failed')
    end
  end
end
