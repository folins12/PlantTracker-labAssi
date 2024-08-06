Rails.application.routes.draw do
  root 'home#index'
  #get 'reservations/new'
  #get 'reservations/create'
  #get 'sessions/new'
  #get 'sessions/create'
  #get 'sessions/destroy'
  #get 'registrations/new'
  #get 'registrations/create'
  get 'about', to: 'home#about', as: 'about'

  get 'myplants', to: 'myplants#index'

  get 'infoplants', to: 'infoplants#index'
  get 'infoplants/:id', to: 'infoplants#show', as: 'infoplant'

  get 'nurseries', to: 'nurseries#index'
  get 'nurseries/:id', to: 'nurseries#show', as: 'nursery'
  #get 'locations/get_coordinates', to: 'locations#get_coordinates'

  get 'register', to: 'registrations#new'
  post 'register', to: 'registrations#create'

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  get 'user_profile', to: 'users#profile'
  patch 'user_profile', to: 'users#update'
  get 'nursery_profile', to: 'nursery_profile#profile', as: 'nursery_profile'
  resources :users, only: [:show, :update]
  post 'reserve', to: 'nursery_plants#reserve'
end
