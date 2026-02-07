class ForecastsController < ApplicationController
  include IpHelper

  DEFAULT_TIMEZONE = 'UTC'.freeze

  before_action :detect_user_timezone
  before_action :set_detected_city, only: %i[index detect_location]

  def index
    if params[:address].present?
      result = ForecastRetriever.new(params[:address]).call

      if result[:success]
        @forecast = result[:forecast]
      else
        flash.now[:error] = result[:error]
      end
    end
  rescue StandardError => e
    Rails.logger.error "Error in index action: #{e.message}\n#{e.backtrace.join("\n")}"
    flash.now[:error] = I18n.t('errors.general.unexpected_error')
  end

  def detect_location
    if @detected_city
      redirect_to root_path(address: @detected_city), allow_other_host: false
    else
      redirect_to root_path
    end
  end

  private

  def detect_user_timezone
    timezone_result = TimezoneService.new(request.remote_ip).call

    if timezone_result[:success] && timezone_result[:timezone]
      @user_timezone = timezone_result[:timezone]
      Time.zone = @user_timezone
    else
      @user_timezone = DEFAULT_TIMEZONE
      Time.zone = DEFAULT_TIMEZONE
    end
  end

  def set_detected_city
    @detected_city = detect_city_from_ip
  end

  def detect_city_from_ip
    return nil if localhost_or_private?(request.remote_ip)

    result = Geocoder.search(request.remote_ip).first
    CityFormatter.format(result)
  rescue StandardError => e
    Rails.logger.error "IP geolocation failed: #{e.message}"
    nil
  end
end
