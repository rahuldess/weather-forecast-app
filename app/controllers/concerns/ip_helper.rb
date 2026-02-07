module IpHelper
  def localhost_or_private?(ip_address)
    ip_address == '127.0.0.1' ||
      ip_address == '::1' ||
      ip_address.to_s.start_with?('192.168.') ||
      ip_address.to_s.start_with?('10.')
  end
end
