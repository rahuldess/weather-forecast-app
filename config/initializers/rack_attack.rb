# Rack Attack Configuration
# Protect your app from bad clients and abusive requests

class Rack::Attack
  ### Configure Cache ###
  # Use Rails cache store for Rack::Attack throttling
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  ### Throttle Requests ###
  
  # Throttle all requests by IP (60 requests per minute)
  throttle('req/ip', limit: 60, period: 1.minute) do |req|
    req.ip
  end

  # Throttle forecast requests by IP (20 requests per minute)
  throttle('forecasts/ip', limit: 20, period: 1.minute) do |req|
    req.ip if req.path.start_with?('/forecasts')
  end

  # Throttle POST requests more aggressively (10 per minute)
  throttle('post/ip', limit: 10, period: 1.minute) do |req|
    req.ip if req.post?
  end

  ### Custom Throttle Response ###
  self.throttled_responder = lambda do |env|
    retry_after = env['rack.attack.match_data'][:period]
    [
      429,
      {
        'Content-Type' => 'text/html',
        'Retry-After' => retry_after.to_s
      },
      ["<html><body><h1>Rate Limit Exceeded</h1><p>Please try again in #{retry_after} seconds.</p></body></html>"]
    ]
  end

  ### Allow Localhost ###
  # Always allow requests from localhost (for development)
  safelist('allow-localhost') do |req|
    req.ip == '127.0.0.1' || req.ip == '::1'
  end

  ### Logging ###
  ActiveSupport::Notifications.subscribe('rack.attack') do |name, start, finish, request_id, payload|
    req = payload[:request]
    if [:throttle, :blocklist].include?(req.env['rack.attack.match_type'])
      Rails.logger.warn "[Rack::Attack] #{req.env['rack.attack.match_type']} #{req.ip} #{req.request_method} #{req.fullpath}"
    end
  end
end
