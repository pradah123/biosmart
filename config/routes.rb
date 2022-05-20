Rails.application.routes.draw do
  mount Rswag::Ui::Engine => '/api-docs'
  mount Rswag::Api::Engine => '/api-docs'
    
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

  #get '/regions-contests/:contest_slug/:region_slug', to: 'pages#region_contest'
  #get '/regions/:slug', to: 'pages#region'
  #get '/contests/:slug', to: 'pages#contest'

  get '/observations/more', to: 'pages#get_more'

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
      get '/region/:id', to: 'region#show'
      put '/region/:id', to: 'region#update'
      patch '/region/:id', to: 'region#update'      
      delete '/region/:id', to: 'region#destroy'

      get '/region/polygons', to: 'region#polygons'
      get '/region/data/:region_id/:contest_id', to: 'region#data'

      post '/observations', to: 'observation#bulk_create'
      get '/observations/more', to: 'observation#get_more'
      get '/observations/region/:id', to: 'observation#region'
      get '/observations/participation/:id', to: 'observation#participation'
      get '/observations/contest/:id', to: 'observation#contest'
    end
  end

  get "*path", to: redirect('404.html')

end