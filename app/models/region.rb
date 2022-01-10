class Region < ApplicationRecord
    has_many :contests, through: :region_contest
    
    def format_for_api(params={})
        data = {
            id: id,
            name: name,
            description: description,
            header_image_url: header_image_url,
            logo_image_url: logo_image_url,
            region_url: region_url,
            refresh_interval_mins: refresh_interval_mins,
            updated_at: updated_at
        }
        if params[:polygon_format] == :geo_json
            data[:polygon] = RGeo::GeoJSON.encode(polygon)
        end
        
        return data
    end
end
