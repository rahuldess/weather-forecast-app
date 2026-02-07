# Weather Forecast App

A simple web application that shows you the weather forecast for any location in the world. Just type in an address, and get instant weather information including current conditions and a 7-day forecast.

---

## 📋 Assignment Requirements

This project was built to fulfill the following requirements:

### Core Requirements ✅

- ✅ **Built with Ruby on Rails** - Rails 8.1.2 with Ruby 3.3.6
- ✅ **Accept an address as input** - User-friendly search interface
- ✅ **Retrieve forecast data** - Integration with Open-Meteo API
  - ✅ Current temperature (required)
  - ✅ High/Low temperatures (bonus)
  - ✅ Extended 7-day forecast (bonus)
- ✅ **Display forecast details** - Clean, intuitive UI showing all weather information
- ✅ **Cache by zip code for 30 minutes** - Implemented with Rails.cache
- ✅ **Display cache indicator** - Visual indicators showing fresh vs cached data

### Assignment Assumptions Made

Based on the assignment's open interpretation approach, the following assumptions were made:

1. **Worldwide Support**: While the assignment mentions zip codes, the app supports international addresses. For addresses without zip codes, a fallback cache key strategy is used.

2. **Free APIs Preferred**: Chose Open-Meteo API (no API key required) over commercial alternatives for ease of setup and demonstration.

3. **User Experience Matters**: Even though "functionality is a priority over form," a clean, professional UI was implemented to demonstrate production-ready thinking.

4. **Service-Oriented Architecture**: Implemented proper separation of concerns with service objects (GeocodingService, WeatherService) for maintainability and testability.

5. **Production-Ready Mindset**: Included testing, security scanning, and code quality tools to demonstrate professional development practices.

---

## Enhancements Beyond Requirements

This implementation goes beyond the basic requirements with the following enhancements:

### 1. **Extended Weather Data**

- Current conditions with weather codes (Clear, Rainy, Snowy, etc.)
- "Feels like" temperature
- Humidity percentage
- Wind speed
- Precipitation probability for 7-day forecast
- Detailed daily forecasts

### 2. **Advanced Features**

- **Timezone Detection**: Automatically detects user's timezone via IP address
- **Location Detection**: "Use My Location" button with GPS-based precise location
- **Address Autocomplete**: Real-time address suggestions using Nominatim API
- **Temperature Unit Toggle**: Switch between Fahrenheit and Celsius on-the-fly
- **Worldwide Support**: Works with any address globally, not just US addresses

### 3. **API Resilience & Reliability**

- **Circuit Breaker Pattern**: Protects against cascading failures using Circuitbox
  - Separate circuit breakers for Weather, Geocoding, and Timezone APIs
  - Automatic failure detection and recovery
  - Prevents overwhelming failing services
- **Retry Logic**: Automatic retry with exponential backoff using Retriable gem
  - Handles transient network failures gracefully
  - Configurable retry attempts and delays
- **Stale Cache Fallback**: Returns cached data when APIs are unavailable
  - Graceful degradation during outages
  - User-friendly error messages
- **Timeout Protection**: Prevents hanging requests from blocking the application

### 4. **Professional Code Quality**

- **Comprehensive Test Suite**: RSpec tests with BDD approach
  - Service layer tests
  - Model tests
  - Controller tests
  - Request specs
- **Code Quality Tools**:
  - RuboCop for style enforcement
  - Brakeman for security scanning
  - Rails Best Practices checker
  - Bullet for N+1 query detection
- **Security Features**:
  - Rack::Attack for rate limiting
  - Input validation and sanitization
  - No security vulnerabilities (Brakeman verified)

### 5. **Production-Ready Infrastructure**

- **Redis-Ready Caching**: Easy switch from memory to Redis for production
- **Modular Architecture**: Weather service organized into focused modules
  - `Weather::ApiConfig` - Centralized API configuration
  - `Weather::Codes` - Weather condition mappings
  - `Weather::ForecastBuilder` - Forecast data construction
- **Error Handling**: Graceful error messages for all failure scenarios
- **Logging**: Comprehensive logging for debugging and monitoring
- **Environment Management**: dotenv-rails for secure configuration
- **Rate Limiting**: Protection against API abuse

### 6. **Developer Experience**

- **Clear Documentation**: Comprehensive README with installation guide
- **Code Organization**: Service-oriented architecture for maintainability
- **Debugging Tools**: Pry-Rails for enhanced development experience
- **Test Helpers**: WebMock and VCR for API testing
- **Shoulda Matchers**: Cleaner, more readable tests
- **Git Pre-Push Hooks**: Automated quality checks before every push (tests, linting, security)

### 7. **User Experience Enhancements**

- **Cache Status Visibility**: Clear indicators showing data freshness
- **Loading States**: Visual feedback during API calls
- **Responsive Design**: Works on desktop and mobile devices
- **Intuitive Interface**: Google-style search with autocomplete
- **Error Messages**: User-friendly error messages in plain language
- **Graceful Degradation**: App continues working even when external APIs have issues

---

## What Does This App Do?

This weather app helps you:

- **Check the weather anywhere** - Enter any address worldwide (like "Times Square, New York" or "Eiffel Tower, Paris")
- **See current conditions** - Temperature, humidity, wind speed, and how it feels outside
- **Plan ahead** - View a 7-day forecast with high/low temperatures and rain chances
- **Save time** - The app remembers recent searches for 30 minutes, so you get instant results

The app automatically detects your location and timezone to show you relevant weather information right away.

## How It Works (Simple Explanation)

1. You type in an address (like "350 Fifth Avenue, New York")
2. The app finds the exact location on a map
3. It fetches weather data from a free weather service
4. You see the current weather and forecast for the next 7 days
5. If you search the same area again within 30 minutes, you get instant results (no waiting!)

<img width="935" height="1078" alt="image" src="https://github.com/user-attachments/assets/d37b7084-c2a1-44a7-9b94-00d749b7965b" />

## What You Need Before Installing

Before you can run this app on your computer, make sure you have:

- **Ruby** (version 3.3.6) - The programming language this app is built with
- **A web browser** - Like Chrome, Firefox, or Safari
- **Internet connection** - To fetch weather data

Don't worry if you don't have Ruby installed yet - we'll guide you through it!

## Installation Guide

Follow these steps to get the app running on your computer:

### Step 1: Check if Ruby is Installed

Open your Terminal (on Mac, press `Cmd + Space`, type "Terminal", and press Enter).

Type this command and press Enter:

```bash
ruby --version
```

If you see something like `ruby 3.3.6`, you're good to go! If not, you'll need to install Ruby first.

#### Installing Ruby (if needed)

The easiest way is using a tool called `asdf`:

```bash
# Install asdf (if you don't have it)
brew install asdf

# Add asdf to your shell
echo -e "\n. $(brew --prefix asdf)/libexec/asdf.sh" >> ~/.zshrc
source ~/.zshrc

# Install Ruby plugin
asdf plugin add ruby

# Install Ruby 3.3.6
asdf install ruby 3.3.6
asdf global ruby 3.3.6
```

### Step 2: Navigate to the Project Folder

In your Terminal, go to where you downloaded this project:

```bash
cd /Users/T946500/Desktop/weather_forecast_app
```

### Step 3: Install Required Components

The app needs some additional components (called "gems"). Install them with:

```bash
bundle install
```

This might take a few minutes. You'll see lots of text scrolling by - that's normal!

### Step 4: Set Up the Database

Even though this is a simple app, it needs a small database. Set it up with:

```bash
bundle exec rails db:create
bundle exec rails db:migrate
```

### Step 4.5: Install Git Pre-Push Hooks (Optional but Recommended)

Install automated quality checks that run before every push:

```bash
bin/setup-hooks
```

This installs hooks that automatically run tests, linting, and security scans before pushing code. See [PRE_PUSH_HOOKS.md](PRE_PUSH_HOOKS.md) for details.

### Step 5: Start the App

Now you're ready to run the app! Type:

```bash
bundle exec rails server
```

You should see a message like:

```
* Listening on http://127.0.0.1:3000
```

**Congratulations! The app is now running!** 🎉

### Step 6: Open the App in Your Browser

Open your web browser and go to:

```
http://localhost:3000
```

You should see the weather app homepage!

## How to Use the App

1. **On the homepage**, you'll see a search box
2. **Type any address** you want to check the weather for:
   - "1600 Pennsylvania Avenue, Washington DC"
   - "Big Ben, London"
   - "Tokyo Tower, Japan"
   - Or just a city name like "Seattle" or "Paris"
3. **Click "Get Forecast"**
4. **View the results**:
   - Current temperature and conditions
   - How it feels outside
   - Today's high and low temperatures
   - 7-day forecast with daily details
   - Whether the data is fresh or from recent cache

### Pro Tips

- **Use the "Use My Location" button** to automatically detect your city (works best when not on localhost)
- **Try the same address twice** within 30 minutes to see how caching works - the second time is instant!
- **The app works worldwide** - try addresses from different countries

## Stopping the App

When you're done using the app:

1. Go back to your Terminal window
2. Press `Ctrl + C` (hold Control and press C)
3. The app will stop running

## Troubleshooting

### Problem: "Command not found" errors

**Solution**: Make sure Ruby and Bundler are properly installed. Try running:

```bash
gem install bundler
```

### Problem: The app won't start

**Solution**: Make sure you're in the correct folder:

```bash
cd /Users/T946500/Desktop/weather_forecast_app
```

Then try starting again:

```bash
bundle exec rails server
```

### Problem: Can't find the page in browser

**Solution**: Make sure you're going to exactly `http://localhost:3000` (not https, and not a different port number)

### Problem: Weather data not loading

**Solution**:

- Check your internet connection
- Make sure the address you entered is valid
- Try a simpler address like just a city name

### Problem: "Use My Location" doesn't work

**Solution**: This feature only works when accessing the app from a public IP address. When running locally (localhost), it can't detect your location. Just type in your city name instead!

## Project Structure (For the Curious)

If you want to understand how the app is organized:

```
weather_forecast_app/
├── app/                          # Main application code
│   ├── controllers/              # Handles web requests
│   ├── models/                   # Data structures
│   ├── services/                 # Business logic (weather fetching, geocoding)
│   └── views/                    # What you see in the browser
├── config/                       # App settings
├── spec/                         # Automated tests
├── Gemfile                       # List of required components
└── README.md                     # This file!
```

## Technical Details (For Developers)

<details>
<summary>Click to expand technical information</summary>

### Built With

- **Ruby on Rails 8.1.2** - Web application framework
- **SQLite3 2.9** - Lightweight database
- **Open-Meteo API** - Free weather data (no API key needed!)
- **Geocoder** - Converts addresses to coordinates
- **HTTParty** - Makes API requests
- **Circuitbox** - Circuit breaker pattern for API resilience
- **Retriable** - Automatic retry logic with exponential backoff
- **Redis-ready** - For production caching

### Key Features

- Service-oriented architecture with modular design
- 30-minute caching by zip code with stale cache fallback
- Circuit breaker pattern for API resilience
- Automatic retry logic for transient failures
- Comprehensive RSpec test suite
- Rate limiting with Rack::Attack
- Security scanning with Brakeman
- Code quality checks with RuboCop
- Timezone detection
- IP-based location detection

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run with detailed output
bundle exec rspec --format documentation
```

### Code Quality Checks

```bash
# Check code style
bundle exec rubocop

# Security scan
bundle exec brakeman

# Auto-fix style issues
bundle exec rubocop --autocorrect-all
```

### Git Pre-Push Hooks

This project includes automated pre-push hooks that run quality checks before every push:

```bash
# Normal push - runs all checks automatically
git push origin main

# Checks that run:
# ✅ RSpec tests (all specs must pass)
# ✅ RuboCop linting (code style compliance)
# ✅ Brakeman security scan (no vulnerabilities)
```

**What happens:**

- If all checks pass ✅ → Push proceeds
- If any check fails ❌ → Push is blocked until you fix the issues

**Bypass checks (emergency only):**

```bash
git push --no-verify  # NOT RECOMMENDED
```

📚 **Full documentation**: See [PRE_PUSH_HOOKS.md](PRE_PUSH_HOOKS.md) for detailed usage, troubleshooting, and best practices.

### Environment Configuration

Copy the example environment file:

```bash
cp .env.example .env
```

Edit `.env` if you need to configure Redis or other settings for production.

### API Information

- **Weather Data**: [Open-Meteo API](https://open-meteo.com/) - Free, no API key required
- **Geocoding**: Nominatim (OpenStreetMap) - Free, no API key required
- **Rate Limits**: Built-in protection with Rack::Attack

### Caching Strategy

- Cache key: `weather_forecast_{zip_code}`
- Expiration: 30 minutes
- Storage: Memory (development), Redis-ready (production)

</details>

## Need Help?

If you run into any issues:

1. Make sure you followed all installation steps in order
2. Check the Troubleshooting section above
3. Try stopping the app (`Ctrl + C`) and starting it again
4. Make sure you have a stable internet connection

## What's Next?

Once you have the app running, you can:

- Explore the code in the `app/` folder
- Run the automated tests with `bundle exec rspec`
- Try modifying the views in `app/views/forecasts/`
- Add new features!

## License

This project was created as a demonstration application.

---

**Enjoy checking the weather!** ☀️🌧️⛈️❄️

Built with Ruby on Rails
