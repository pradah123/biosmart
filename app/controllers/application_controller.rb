require "biosmart_api_error.rb"

class ApplicationController < ActionController::API
    rescue_from StandardError do |e|
        error(e)
    end

    rescue_from BiosmartAPIError do |e|
        biosmart_api_error(e)
    end

    def routing_error
        raise ActionController::RoutingError.new(params[:path])
    end

    protected

    def biosmart_api_error(e)
        error_info = {
            error: BiosmartAPIError::EXCEPTION_TYPE,
            exception: "#{e.class.name} : #{e.message}",
            message: e.message
        }
        render :json => error_info.to_json, :status => :bad_request
    end

    def error(e)
        #render :template => "#{Rails::root}/public/404.html"
        if ENV["ORIGINAL_FULLPATH"] =~ /^\/api/
            error_info = {
                :error => "internal-server-error",
                :exception => "#{e.class.name} : #{e.message}",
                message: e.message
            }
            error_info[:trace] = e.backtrace[0,10] if Rails.env.development?
            render :json => error_info.to_json, :status => :internal_server_error
        else
            #render :text => "500 Internal Server Error", :status => 500 # You can render your own template here
            raise e
        end
    end
end
