Geocoder.configure(
  timeout: 5, # Reduced from 10 to match weather API timeout
  lookup: :mapbox,
  api_key: ENV['MAPBOX_API_KEY'],  # Get free token from https://www.mapbox.com/
  cache: Rails.cache,
  cache_prefix: 'geocoder:',
  always_raise: [],
  units: :mi,
  distances: :linear,
  # Use separate timeouts for connection vs read
  http_options: {
    open_timeout: 2,  # Time to establish connection
    read_timeout: 5   # Time to read response
  }
)

# IMPORTANT: Set MAPBOX_API_KEY in your .env file
# See GEOCODING_SETUP.md for detailed instructions on getting a free Mapbox API key
