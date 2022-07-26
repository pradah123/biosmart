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

  def self.get_bounding_box(region_polygon)
    west = nil
    east = nil
    south = nil
    north = nil
    region_polygon.each do |p|
      min_lng, max_lng = p["coordinates"].map{|co| co.first}.minmax
      min_lat, max_lat = p["coordinates"].map{|co| co.last}.minmax
      west = min_lng if west.blank? || min_lng < west
      east = max_lng if east.blank? || max_lng > east
      south = min_lat if south.blank? || min_lat < south
      north = max_lat if north.blank? || max_lat > north
    end
    
    return west, east, south, north
  end
end
