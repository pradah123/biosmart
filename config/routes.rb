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
        scope :observations do
            controller :observations do
                get '/count', action: :count
            end
        end
        scope :identifications do
            controller :observations do
                get '/count', action: :identifications_count
            end
        end
        scope :species do
            controller :observations do
                get '/count', action: :species_count
            end
        end
        scope :participants do
            controller :observations do
                get '/count', action: :participants_count
            end
        end
    end
end
