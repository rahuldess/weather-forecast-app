module TemperatureFormattable
  def format_temperature(value, unit = 'F')
    return 'N/A' unless value

    "#{value}°#{unit}"
  end
end
