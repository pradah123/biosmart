class StatusController < ApplicationController
    def index
        render  json: {status: :healthy}, 
                status: :ok
    end
end
