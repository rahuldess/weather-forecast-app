require_relative "boot"
require "rails/all"

Bundler.require(*Rails.groups)

module WeatherForecastApp
  class Application < Rails::Application
    config.load_defaults 7.1
    config.autoload_lib(ignore: %w(assets tasks))
    config.cache_store = :memory_store, { size: 64.megabytes }
    config.autoload_paths << Rails.root.join('app', 'services')
  end
end
