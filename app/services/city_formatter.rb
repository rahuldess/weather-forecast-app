# Service to format city names from geocoder results
class CityFormatter
  def self.format(geocoder_result)
    return nil unless geocoder_result&.city

    if geocoder_result.country_code == 'US' && geocoder_result.state
      "#{geocoder_result.city}, #{geocoder_result.state}"
    elsif geocoder_result.city && geocoder_result.country
      "#{geocoder_result.city}, #{geocoder_result.country}"
    else
      geocoder_result.city
    end
  end
end
