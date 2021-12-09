Rails.application.routes.draw do
    # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
    scope :api do
        resources :region
        scope :admin do
            controller :admin do
                post '/', action: :create
                post :login
                post :logout
            end
        end
        scope :count do
            controller :count do
                get '/observations', action: :observations_count
                get '/identifications', action: :observations_count
                get '/species', action: :species_count
                get '/participants', action: :participants_count
            end
        end
        scope :observations do
            controller :observations do
                get '/', action: :index
            end
        end
    end
end
