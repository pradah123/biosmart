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


  ## Generate polygon coordinates from given lat,lng and radius
  def self.get_boundary_for_greater_area center_lat, center_lng, radius
    point = Geokit::LatLng.new center_lat, center_lng

    east  = point.endpoint(0,   radius, units: :kms)
    ne    = point.endpoint(45,  radius, units: :kms)
    north = point.endpoint(90,  radius, units: :kms)
    nw    = point.endpoint(135, radius, units: :kms)
    west  = point.endpoint(180, radius, units: :kms)
    sw    = point.endpoint(225, radius, units: :kms)
    south = point.endpoint(270, radius, units: :kms)
    se    = point.endpoint(315, radius, units: :kms)

    return east, ne, north, nw, west, sw, south, se
  end

end
