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
  get '/observations/more', to: 'pages#get_more'

  get '/contest/:slug', to: 'pages#contest'
  get '/:region_slug/:contest_slug', to: 'pages#region_contest'
  get '/:slug', to: 'pages#region'

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
      get 'contest/data/', to: 'contest#data'
      get '/contest/:contest_id/regions', to: 'participation#search'
      get '/contest/:contest_id/regions/:region_id/observations', to: 'observation#search'

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
      get '/observations/contest_region', to: 'observation#contest_region'
      get '/observations/region/:id', to: 'observation#region'
      get '/observations/participation/:id', to: 'observation#participation'
      get '/observations/contest/:id', to: 'observation#contest'
      get '/observations/:id', to: 'observation#data'

    end
  end

  get "*path", to: redirect('/')

end