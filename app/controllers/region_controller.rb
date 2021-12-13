class RegionController < ApplicationController
    def index
        if params[:id].blank?
            raise  BiosmartAPIError.new(
                "Invalid region ID. Please try again.",
                BiosmartAPIError::EXCEPTION_TYPE
            )
        end
        @region = Region.find(params[:id])
        if @region.blank?
            raise  BiosmartAPIError.new(
                "Invalid region ID. Please try again.",
                BiosmartAPIError::EXCEPTION_TYPE
            )
        end
        region_data = @region.format_for_api({polygon_format: :geo_json})
        
        render  json: region_data, 
                status: :ok
    end
end
