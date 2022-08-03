require 'timezone_finder'

module Utils
  def self.get_utc_time(lat:, lng:, date_s:, time_s:)
    if lat == nil
      raise ArgumentError, 'Please provide a valid lat value'
    end
    if lng == nil
      raise ArgumentError, 'Please provide a valid lng value'
    end
    if date_s == nil
      raise ArgumentError, 'Please provide a valid date string value'
    end
    utc_dttm = date_s
    tf = TimezoneFinder.create
    tz_str = tf.timezone_at(lng: lng, lat: lat) || 
            tz_str = tf.timezone_at(lng: lng, lat: lat) || 
            tz_str = tf.certain_timezone_at(lng: lng, lat: lat)
    if tz_str != nil && time_s != nil
      timezone = TZInfo::Timezone.get(tz_str)
      utc_dttm = timezone.local_to_utc(
        Time.strptime("#{date_s} #{time_s}", '%Y-%m-%d %H:%M')
      )
    end
    
    return utc_dttm.to_s
  end

  def self.get_bounding_box(subregion_polygon)
    west, east = subregion_polygon["coordinates"].map{|co| co.first}.minmax
    south, north = subregion_polygon["coordinates"].map{|co| co.last}.minmax
    
    return west, east, south, north
  end

  ## Generate bounding box coordinates
  ## get_bounding_box_with(Float, Float, Int) -> Array
  def self.get_bounding_box_coordinates_with(center_lat:, center_lng:, at_distance:)
    point = Geokit::LatLng.new(center_lat, center_lng)
    ne    = point.endpoint(45,  at_distance, units: :kms)
    nw    = point.endpoint(135, at_distance, units: :kms)
    sw    = point.endpoint(225, at_distance, units: :kms)
    se    = point.endpoint(315, at_distance, units: :kms)

    return ne, nw, sw, se
  end

  ## Generate polygon geojson array from boundary coordinates
  ## generate_polygon_geojson(Float, Float, Float, Float) -> String
  def self.generate_polygon_geojson(ne, nw, sw, se)
    geojson_polygons = []
    geojson = {}
    geojson['type'] = 'Polygon'
    geojson['coordinates'] = []

    geojson['coordinates'].push([ne.lng, ne.lat])
    geojson['coordinates'].push([nw.lng, nw.lat])
    geojson['coordinates'].push([sw.lng, sw.lat])
    geojson['coordinates'].push([se.lng, se.lat])
    geojson['coordinates'].push([ne.lng, ne.lat])
    
    geojson_polygons.push geojson unless geojson['coordinates'].blank?

    return JSON.generate geojson_polygons
  end

end
