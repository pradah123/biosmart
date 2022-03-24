class Region < ApplicationRecord
  belongs_to :user
  has_and_belongs_to_many :observations
  has_many :participations
  has_many :contests, through: :participations

  enum status: [:online, :offline, :deleted]  






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
        data[:polygon] = RGeo::GeoJSON.encode(multi_polygon)
    end
    
    return data
  end

end
