Rails.application.routes.draw do
  root 'forecasts#index'
  get 'detect_location', to: 'forecasts#detect_location', as: 'detect_location'
  get 'up' => 'rails/health#show', as: :rails_health_check
end
