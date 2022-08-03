class NeighboringRegion
  # initialize(Region, Int) -> Void
  def initialize(base_region, size)
    @base_region = base_region
    @size = size
    @existing_region = @base_region.neighboring_regions.where(size: @size).first
  end

  # get_region() -> Region
  def get_region()
    r = @existing_region
    
    # NOTE: If neighboring region does not exists, create new region
    r = Region.new() if r.blank?

    r.size = @size
    r.name = name()
    r.base_region_id = @base_region.id
    r.base_lat = @base_region.lat
    r.base_lng = @base_region.lng
    r.base_polygon_geojson = @base_region.get_polygon_json
    r.raw_polygon_json = get_polygon_geojson()
        
    return r    
  end

  # name() -> String
  def name()
    return "#{@base_region.name} #{@size}X"    
  end

  # get_polygon_geojson() -> String
  def get_polygon_geojson()
    farthest_point_dist = @base_region.get_distance_of_farthest_point()
    
    # Get bounding box for larger region
    ne, nw, sw, se = Utils.get_bounding_box_coordinates_with(
      center_lat: @base_region.base_lat, 
      center_lng: @base_region.base_lng, 
      at_distance: farthest_point_dist * @size
    )

    # Generate geojson from bounding box
    polygon_geojson = Utils.generate_polygon_geojson(ne, nw, sw, se)

    return polygon_geojson
  end

end
