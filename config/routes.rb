Rails.application.routes.draw do
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
  root to: 'offers#index'
  resources :offers, only: %i[create index show update destroy]
  get 'scrape', to: 'offers#scrape'
end
