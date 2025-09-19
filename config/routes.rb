Rails.application.routes.draw do
  # Incident tracking system
  resources :incidents do
    member do
      patch :acknowledge
      patch :resolve
    end
  end

  # Set root to incidents dashboard
  root "incidents#index"

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
