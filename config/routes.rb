Rails.application.routes.draw do
    
  mount RailsAdmin::Engine, at: '/dashboard/admin', as: 'rails_admin'
  match "/dashboard/delayed_job" => DelayedJobWeb, :anchor => false, :via => [:get, :post]

  get '/', to: 'pages#top'
  get '/regions', to: 'pages#regions'
  get '/contests', to: 'pages#contests'
  get '/participants', to: 'pages#participations'
  get '/users', to: 'pages#users'

  get '/regions/:region_id/contests/:contest_id(/:contest_slug/:region_slug)', to: 'pages#region_contest'
  get '/regions/:id(/:slug)', to: 'pages#region'
  get '/contests/:id(/:slug)', to: 'pages#contest'

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
      get '/region/data/:region_id/:contest_id', to: 'region#data'

      post '/observations', to: 'observation#bulk_create'
      get '/observations/more', to: 'observation#get_more'
    end
  end

  get "*path", to: redirect('404.html')

end