class AdminController < ApplicationController
    def create
        @admin = Admin.new(password_params)
        @admin.save
        render  json: @admin, 
                except: [:password_digest, :deleted_at, :updated_at], 
                status: :ok
    end

    def logout
        @admin = Admin.first
        render  json: @admin, 
                except: [:password_digest, :deleted_at, :updated_at], 
                status: :ok
    end

    def login
        @admin = Admin.find_by(email: params[:email])
        if !@admin.authenticate(params[:password])
            raise  BiosmartAPIError.new(
                "Invalid email or password. Please try again.",
                BiosmartAPIError::EXCEPTION_TYPE
            )
        end
        render  json: @admin, 
                except: [:password_digest, :deleted_at, :updated_at], 
                status: :ok
    end
    
    private
    def password_params
        params.require(:admin).permit(:name, :email, :password)
    end
end
