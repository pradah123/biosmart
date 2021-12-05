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
    end
end
