Rails.application.routes.draw do
    
  mount RailsAdmin::Engine, at: '/dashboard', as: 'rails_admin'

  get '/', to: 'pages#top'
  get '/regions', to: 'pages#regions'
  get '/contests', to: 'pages#contests'
  get '/participants', to: 'pages#participations'
  get '/users', to: 'pages#users'
  get '/region/:id', to: 'pages#region'
  get '/contest/:id', to: 'pages#contest'
  get '/region/:region_id/contest/:contest_id', to: 'pages#region_contest'
 
  namespace :api do
    namespace :v1 do
      post '/user', to: 'user#create'
      put '/user', to: 'user#update'
      delete '/user', to: 'user#close_account'
      post '/user/login', to: 'user#login'
      post '/user/logout', to: 'user#logout'
      
      post '/contest', to: 'contest#create'
      put '/contest', to: 'contest#update'
      delete '/contest', to: 'contest#destroy'      

      post '/participation', to: 'participation#create'
      put '/participation', to: 'participation#update'
      delete '/participation', to: 'participation#destroy'    

      post '/region', to: 'region#create'
      put '/region', to: 'region#update'
      delete '/region', to: 'region#destroy'

      get '/region/polygons', to: 'region#polygons'
      post '/observations', to: 'observation#bulk_create'
    end
  end

  get "*path", to: redirect('404.html')

end