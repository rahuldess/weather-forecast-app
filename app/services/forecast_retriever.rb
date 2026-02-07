# Service to orchestrate forecast retrieval from geocoding and weather services
class ForecastRetriever < BaseService
  def initialize(address)
    @address = address
  end

  def call
    return error_result(I18n.t('errors.forecast.address_required')) if @address.blank?

    geocoding_result = GeocodingService.new(@address).call
    return geocoding_result unless geocoding_result[:success]

    weather_result = WeatherService.new(
      geocoding_result[:latitude],
      geocoding_result[:longitude],
      geocoding_result[:zip_code]
    ).call
    return weather_result unless weather_result[:success]

    success_result(
      forecast: Forecast.from_service_results(geocoding_result, weather_result)
    )
  rescue StandardError => e
    Rails.logger.error "Forecast retrieval failed: #{e.message}\n#{e.backtrace.join("\n")}"
    error_result(I18n.t('errors.forecast.retrieval_failed'))
  end
end
