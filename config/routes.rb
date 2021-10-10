Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'offers#index'
  resources :offers, only: %i[index destroy edit update]
  get 'scrape', to: 'offers#scrape'
end
