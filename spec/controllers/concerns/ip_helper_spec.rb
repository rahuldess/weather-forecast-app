require 'rails_helper'

RSpec.describe IpHelper, type: :controller do
  controller(ApplicationController) do
    include IpHelper

    def test_action
      render plain: localhost_or_private?(params[:ip])
    end
  end

  before do
    routes.draw { get 'test_action' => 'anonymous#test_action' }
  end

  describe '#localhost_or_private?' do
    context 'with localhost addresses' do
      it 'returns true for 127.0.0.1' do
        result = controller.send(:localhost_or_private?, '127.0.0.1')
        expect(result).to be true
      end

      it 'returns true for ::1 (IPv6 localhost)' do
        result = controller.send(:localhost_or_private?, '::1')
        expect(result).to be true
      end
    end

    context 'with private IP addresses' do
      it 'returns true for 192.168.x.x addresses' do
        private_ips = [
          '192.168.0.1',
          '192.168.1.1',
          '192.168.1.100',
          '192.168.255.255'
        ]

        private_ips.each do |ip|
          result = controller.send(:localhost_or_private?, ip)
          expect(result).to be(true), "Expected #{ip} to be detected as private"
        end
      end

      it 'returns true for 10.x.x.x addresses' do
        private_ips = [
          '10.0.0.1',
          '10.1.1.1',
          '10.255.255.255',
          '10.10.10.10'
        ]

        private_ips.each do |ip|
          result = controller.send(:localhost_or_private?, ip)
          expect(result).to be(true), "Expected #{ip} to be detected as private"
        end
      end
    end

    context 'with public IP addresses' do
      it 'returns false for public IPv4 addresses' do
        public_ips = [
          '8.8.8.8',
          '1.1.1.1',
          '208.67.222.222',
          '151.101.1.140',
          '172.217.14.206'
        ]

        public_ips.each do |ip|
          result = controller.send(:localhost_or_private?, ip)
          expect(result).to be(false), "Expected #{ip} to be detected as public"
        end
      end

      it 'returns false for addresses starting with 193' do
        result = controller.send(:localhost_or_private?, '193.168.1.1')
        expect(result).to be false
      end

      it 'returns false for addresses starting with 11' do
        result = controller.send(:localhost_or_private?, '11.0.0.1')
        expect(result).to be false
      end
    end

    context 'with edge cases' do
      it 'handles IP addresses as strings' do
        result = controller.send(:localhost_or_private?, '192.168.1.1')
        expect(result).to be true
      end

      it 'returns false for empty string' do
        result = controller.send(:localhost_or_private?, '')
        expect(result).to be false
      end

      it 'returns false for nil' do
        result = controller.send(:localhost_or_private?, nil)
        expect(result).to be false
      end

      it 'handles addresses with leading zeros' do
        result = controller.send(:localhost_or_private?, '192.168.001.001')
        expect(result).to be true
      end
    end
  end
end
