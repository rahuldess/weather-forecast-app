source 'https://rubygems.org'

ruby '3.3.6'

# Rails framework
gem 'rails', '~> 8.1.0'

# Database
gem 'sqlite3', '>= 2.1'

# Web server
gem 'puma', '~> 6.0'

# Asset pipeline
gem 'importmap-rails'
gem 'sprockets-rails'
gem 'stimulus-rails'
gem 'turbo-rails'

# HTTP client for API calls
gem 'httparty', '~> 0.21.0'

# Geocoding for address to coordinates conversion
gem 'geocoder', '~> 1.8'

# Retry logic for transient failures
gem 'retriable', '~> 3.1'

# Circuit breaker pattern
gem 'circuitbox', '~> 2.0'

# Reduces boot times through caching
gem 'bootsnap', require: false

# Production caching with Redis
gem 'redis', '~> 5.0'

# Rate limiting and throttling
gem 'rack-attack'

group :development, :test do
  # Environment variables management
  gem 'dotenv-rails'

  # Debugging
  gem 'debug', platforms: %i[mri windows]
  gem 'pry-byebug'
  gem 'pry-rails'

  # Testing framework
  gem 'factory_bot_rails', '~> 6.4.0'
  gem 'faker', '~> 3.2.0'
  gem 'rspec-rails', '~> 6.1.0'
end

group :test do
  # HTTP request mocking
  gem 'vcr', '~> 6.2.0'
  gem 'webmock', '~> 3.19.0'

  # Test coverage
  gem 'simplecov', require: false

  # Feature testing
  gem 'capybara'
  gem 'selenium-webdriver'

  # Better RSpec matchers
  gem 'shoulda-matchers', '~> 6.0'
end

group :development do
  gem 'web-console'

  # Code quality and linting
  gem 'rubocop', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false

  # Security scanner
  gem 'brakeman', require: false

  # N+1 query detection
  gem 'bullet'

  # Model annotations
  gem 'annotate'

  # Rails best practices checker
  gem 'rails_best_practices', require: false
end
