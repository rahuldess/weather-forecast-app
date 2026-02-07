# Base service class with common functionality
class BaseService
  private

  def error_result(message)
    {
      success: false,
      error: message
    }
  end

  def success_result(data = {})
    {
      success: true
    }.merge(data)
  end
end
