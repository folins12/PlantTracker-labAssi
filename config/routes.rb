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
  post 'addmyplant', to: 'myplants#addmyplant'

  get 'nurseries', to: 'nurseries#index'
  get 'nurseries/:id', to: 'nurseries#show', as: 'nursery'
  #get 'locations/get_coordinates', to: 'locations#get_coordinates'

  get 'register', to: 'registrations#new'
  post 'register', to: 'registrations#create'
  get 'users/fetch_weather', to: 'users#fetch_weather'

  get 'login', to: 'sessions#new'
  post 'login', to: 'sessions#create'
  get 'logout', to: 'sessions#destroy'
  get 'user_profile', to: 'users#profile'
  patch 'user_profile', to: 'users#update'
  post 'removemyplant', to: 'myplants#removemyplant'

  post 'decreserve', to: 'users#decreserve'

  post 'add_to_nursery', to: 'nursery_plants#add_to_nursery'
  post 'addtonursery', to: 'nursery_plants#add_to_nursery'


  get 'nursery_profile', to: 'nursery_profile#profile', as: 'nursery_profile'
  post 'incdisp', to: 'nursery_plants#incdisp'
  post 'decdisp', to: 'nursery_plants#decdisp'
  post 'removenursplant', to: 'nursery_plants#removenursplant'

  resources :users, only: [:show, :update]
  post 'reserve', to: 'nursery_plants#reserve'
end
