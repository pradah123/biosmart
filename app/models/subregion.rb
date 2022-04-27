class Subregion < ApplicationRecord
  belongs_to :region
  belongs_to :data_source, optional: true
  after_save :update_geometry

  def update_geometry
Rails.logger.info "here"
Rails.logger.info raw_polygon_json.inspect

    polygon_geojson = JSON.parse [raw_polygon_json]

Rails.logger.info polygon_geojson.inspect
Rails.logger.info polygon_geojson['type']
Rails.logger.info polygon_geojson['coordinates']
Rails.logger.info polygon_geojson[:type]

    # get rectangle which contains polygon

    lats = polygon_geojson['coordinates'].map { |c| c[0] }
    lngs = polygon_geojson['coordinates'].map { |c| c[1] }    
    lat_min = lats.min
    lat_max = lats.max
    lng_min = lngs.min
    lng_max = lngs.max  

    # get radius of circle which contains rectangle

    r_lat = 0.5*(lat_min+lat_max)
    r_lng = 0.5*(lng_min+lng_max)
    centre_lat = lat_min + r_lat
    centre_lng = lng_min + r_lng

    centre = Geokit::LatLng.new centre_lat, centre_lng
    edge_along_lat = Geokit::LatLng.new lat_max, centre_lng
    edge_along_lng = Geokit::LatLng.new centre_lat, lng_max

    radius_km = [edge_along_lng.distance_from(centre, units: :kilometres), edge_along_lat.distance_from(centre, units: :kilometres) ].max

    if radius_km<=max_radius_km

      self.update_columns centre_lat: centre_lat, centre_lng: centre_lng, radius_km: radius_km

    else

      left_bottom = Geokit::LatLng.new lat_min, lng_min
      right_bottom = Geokit::LatLng.new lat_min, lng_max
      right_top = Geokit::LatLng.new lat_max, lng_max

      size_lat = right_bottom.distance_from right_top, units: :kilometres
      size_lng = left_bottom.distance_from right_bottom, units: :kilometres

      n_maxradius_circles_lat = (size_lat/max_radius_km).ceil
      n_maxradius_circles_lng = (size_lng/max_radius_km).ceil
      if size_lat>size_lng
        radius_km = size_lat/n_circles
        n_circles = n_maxradius_circles_lat
        
        lat0 = lat_min
        lng0 = lng_min + 0 
      else  
        n_circles = n_maxradius_circles_lng
        radius_km = size_lng/n_circles
        lat0 = lat_min + 0
        lng0 = lng_min
      end
    

      # make hexagonal cover of rectangle
      #   centres at edges
      #   work out the
      # loop over circles, and if they have an overlap with the polygon, make a subregion
    end

  end  


  def get_params_dict()
    return JSON.parse(params_json, symbolize_names: true)
  end

end
