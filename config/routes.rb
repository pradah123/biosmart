Rails.application.routes.draw do
    
  mount RailsAdmin::Engine, at: '/dashboard', as: 'rails_admin'

  get '/', to: 'pages#top'
  get '/regions', to: 'pages#regions'
  get '/contests', to: 'pages#contests'
  get '/users', to: 'pages#users'
  get '/region/:id', to: 'pages#region'
  get '/contest/:id', to: 'pages#contest'
 
  namespace :api do
    namespace :v1 do
      post '/user', to: 'user#create'
      put '/user', to: 'user#update'
      delete '/user', to: 'user#close_account'
      post '/user/login', to: 'user#login'
      post '/user/logout', to: 'user#logout'
      
      resources :participants
      resources :regions
      resources :contests
    end
  end

  get "*path", to: redirect('404.html')

end