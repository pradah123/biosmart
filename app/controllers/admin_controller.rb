class AdminController < ApplicationController
    def create
        @admin = Admin.new(password_params)
        @admin.save
        render :json => {
            :name => "Creating a user"
        }
    end

    def index
        render :json => {
            :name => "Fetching a user"
        }
    end

    def login
        render :json => {
            :name => "Login user"
        }
    end
    
    private
    def password_params
      params.require(:admin).permit(:name, :email, :password)
    end
end
