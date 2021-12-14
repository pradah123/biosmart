Rails.application.routes.draw do
    # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
    scope :api do
        scope :regions do
            controller :region do
                get '/:id', action: :index
            end
        end
        scope :admin do
            controller :admin do
                post '/', action: :create
                post :login
                post :logout
            end
        end
        scope :contests do
            controller :contest do
                get '/:contest_id/counts', action: :counts
                get '/:contest_id/observations', action: :observations
            end
        end
        scope :count do
            controller :count do
                get '/observations', action: :observations_count
                get '/identifications', action: :identifications_count
                get '/species', action: :species_count
                get '/participants', action: :participants_count
            end
        end
        scope :observations do
            controller :observations do
                get '/', action: :index
            end
        end
        scope :status do
            controller :status do
                get '/', action: :index
            end
        end
    end
end
