class Subregion < ApplicationRecord
  belongs_to :region
  belongs_to :data_source, optional: true
  after_save :update_geometry

  def update_geometry
    return unless parent_subregion_id.nil?

    polygon_geojson = JSON.parse raw_polygon_json

    # get rectangle which contains polygon

    lats = polygon_geojson['coordinates'].map { |c| c[1] }
    lngs = polygon_geojson['coordinates'].map { |c| c[0] }    
    lat_min = lats.min
    lat_max = lats.max
    lng_min = lngs.min
    lng_max = lngs.max

    # get radius of circle which contains rectangle

    r_lat = 0.5*(lat_max-lat_min)
    r_lng = 0.5*(lng_max-lng_min)
    centre_lat = 0.5*(lat_max+lat_min)
    centre_lng = 0.5*(lng_max+lng_min)

    centre = Geokit::LatLng.new centre_lat, centre_lng
    edge_along_lat = Geokit::LatLng.new lat_max, centre_lng
    edge_along_lng = Geokit::LatLng.new centre_lat, lng_max

    radius_km = Math.sqrt(2)*[centre.distance_to(edge_along_lng, units: :kms), centre.distance_to(edge_along_lat, units: :kms) ].max

    if radius_km<=max_radius_km

      self.update_columns lat: centre_lat, lng: centre_lng, radius_km: radius_km

    else

      left_bottom = Geokit::LatLng.new lat_min, lng_min
      right_bottom = Geokit::LatLng.new lat_min, lng_max
      right_top = Geokit::LatLng.new lat_max, lng_max

      size_lat = right_bottom.distance_to right_top, units: :kms
      size_lng = left_bottom.distance_from right_bottom, units: :kms

      #
      # this is the number of circles of max radius it takes to cover the lat and lng 
      # axes of the bounding box containing the polygon
      #
      n_maxradius_circles_lat = (size_lat/max_radius_km).ceil 
      n_maxradius_circles_lng = (size_lng/max_radius_km).ceil
      
      # 
      # compute the radius such that an integer number of
      # circles fills the smallest edge
      #
      if size_lng>size_lat
        radius_km = size_lng/n_maxradius_circles_lng
      else  
        radius_km = size_lat/n_maxradius_circles_lat
      end   

      dr_lng_km = radius_km*Math.sqrt(3.0)
      dr_lat_km = radius_km*1.5

      dlat = (right_top.lat - right_bottom.lat) / n_maxradius_circles_lat
      dlng = 1.5*dlat
      dlat *= Math.sqrt(3.0)

      lat_circle = lat_min + 0.5*dlat
      lng_circle = lng_min + 0.5*dlng

      #
      # make hexagonal cover of rectangle
      #
      n_maxradius_circles_lng.times do |ilng|
        lat_circle = lat_min
        n_maxradius_circles_lat.times do |ilat|
          if ilng==0 && ilat==0
            update_column :lat, lat_min
            update_column :lng, lng_min
            update_column :radius_km, radius_km
          else            
            Subregion.create! region_id: self.region_id, parent_subregion_id: self.id, raw_polygon_json: self.raw_polygon_json, lat: lat_circle, lng: lng_circle, radius_km: radius_km
          end  
          lat_circle += dlat
        end
        lng_circle += dlng  
      end  
 
    end

  end  


  def get_params_dict()
    return JSON.parse(params_json, symbolize_names: true)
  end

end
