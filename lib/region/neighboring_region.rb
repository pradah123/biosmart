class NeighboringRegion
  # initialize(Region, Int) -> Void
  def initialize(base_region, size)
    @base_region = base_region
    @size = size
    @existing_region = @base_region.neighboring_regions.where(size: @size).first
  end

  # get_region() -> Region
  def get_region()
    # NOTE: If neighboring region does not exists, create new region
    r = @existing_region || Region.new()
    r.size = @size
    r.name = name()
    r.base_region_id = @base_region.id
    r.raw_polygon_json = get_polygon_geojson()
        
    return r    
  end

  # name() -> String
  def name()
    return "#{@base_region.name} #{@size}X"    
  end

  # get_polygon_geojson() -> String
  def get_polygon_geojson()
    scaled_polygons = @base_region.scaled_bbox_geojson(with_multiplier: @size)
    
    return scaled_polygons.to_json
  end

end
