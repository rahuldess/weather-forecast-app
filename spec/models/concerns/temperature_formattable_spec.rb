require 'rails_helper'

RSpec.describe TemperatureFormattable do
  let(:test_class) do
    Class.new do
      include TemperatureFormattable
    end
  end

  let(:instance) { test_class.new }

  describe '#format_temperature' do
    context 'with Fahrenheit' do
      it 'formats temperature with F unit' do
        result = instance.format_temperature(72, 'F')
        expect(result).to eq('72°F')
      end

      it 'formats negative temperature' do
        result = instance.format_temperature(-5, 'F')
        expect(result).to eq('-5°F')
      end

      it 'formats zero temperature' do
        result = instance.format_temperature(0, 'F')
        expect(result).to eq('0°F')
      end

      it 'formats high temperature' do
        result = instance.format_temperature(105, 'F')
        expect(result).to eq('105°F')
      end

      it 'formats decimal temperature' do
        result = instance.format_temperature(72.5, 'F')
        expect(result).to eq('72.5°F')
      end
    end

    context 'with Celsius' do
      it 'formats temperature with C unit' do
        result = instance.format_temperature(22, 'C')
        expect(result).to eq('22°C')
      end

      it 'formats negative Celsius temperature' do
        result = instance.format_temperature(-15, 'C')
        expect(result).to eq('-15°C')
      end

      it 'formats zero Celsius' do
        result = instance.format_temperature(0, 'C')
        expect(result).to eq('0°C')
      end

      it 'formats decimal Celsius temperature' do
        result = instance.format_temperature(22.5, 'C')
        expect(result).to eq('22.5°C')
      end
    end

    context 'with default unit' do
      it 'defaults to Fahrenheit when no unit is provided' do
        result = instance.format_temperature(72)
        expect(result).to eq('72°F')
      end

      it 'uses F as default for positive temperatures' do
        result = instance.format_temperature(85)
        expect(result).to eq('85°F')
      end

      it 'uses F as default for negative temperatures' do
        result = instance.format_temperature(-10)
        expect(result).to eq('-10°F')
      end
    end

    context 'with nil or missing values' do
      it 'returns N/A when value is nil' do
        result = instance.format_temperature(nil, 'F')
        expect(result).to eq('N/A')
      end

      it 'returns N/A when value is nil with Celsius' do
        result = instance.format_temperature(nil, 'C')
        expect(result).to eq('N/A')
      end

      it 'returns N/A when value is nil with default unit' do
        result = instance.format_temperature(nil)
        expect(result).to eq('N/A')
      end
    end

    context 'with various temperature ranges' do
      it 'formats very cold temperatures' do
        result = instance.format_temperature(-40, 'F')
        expect(result).to eq('-40°F')
      end

      it 'formats very hot temperatures' do
        result = instance.format_temperature(120, 'F')
        expect(result).to eq('120°F')
      end

      it 'formats freezing point' do
        result = instance.format_temperature(32, 'F')
        expect(result).to eq('32°F')
      end

      it 'formats boiling point Celsius' do
        result = instance.format_temperature(100, 'C')
        expect(result).to eq('100°C')
      end
    end

    context 'with edge cases' do
      it 'handles integer temperatures' do
        result = instance.format_temperature(75, 'F')
        expect(result).to eq('75°F')
      end

      it 'handles float temperatures' do
        result = instance.format_temperature(75.8, 'F')
        expect(result).to eq('75.8°F')
      end

      it 'handles string unit parameter' do
        result = instance.format_temperature(20, 'C')
        expect(result).to eq('20°C')
      end

      it 'preserves decimal precision' do
        result = instance.format_temperature(72.123, 'F')
        expect(result).to eq('72.123°F')
      end
    end
  end
end
