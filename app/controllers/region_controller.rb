class RegionController < ApplicationController
    def create
        puts params.inspect
        render :json => {
            :name => "Creating a region"
        }
    end

    def index
        render :json => {
            :name => "Fetching a region"
        }
    end
end
