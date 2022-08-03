class NeighborRegion
  @@base_region_id
  @@base_lat
  @@base_lng
  @@base_polygon_geojson
  @@radius
  @@name

  def set_params(region, name, radius)
    @base_region_id = region.id
    @base_lat = region.lat
    @base_lng = region.lng
    @base_polygon_geojson = region.get_polygon_json
    @radius = radius
    @name = name
  end


  ## Create neighbor regions for given base region
  def create_neighbor_regions region
    ## Create neighbor region with 5x bigger radius than the base region
    neighbor_name = region.name + " Locality"
    self.create_neighbor_region_with_size(region, 5, neighbor_name)

    ## Create neighbor region with 25x bigger radius than the base region
    neighbor_name = region.name + " Greater Area"
    self.create_neighbor_region_with_size(region, 25, neighbor_name)

  end


  # Create neighbor region with area as per given radius
  def create_neighbor_region_with_size(region, radius, neighbor_name)
    set_params(region, neighbor_name, radius)
    geojson_polygons = []

    if should_generate_polygon('create')
      geojson_polygons = generate_polygon_geojson_from_base_region(region)
    end

    raw_polygon = JSON.generate geojson_polygons

    Region.create! name: @name,
                  base_region_id: @base_region_id,
                  raw_polygon_json: raw_polygon,
                  size: @radius,
                  description: region.description
  end


  # Update neighbor regions of given base region
  def update_neighbor_regions(region, base_name_changed, base_polygon_changed)

    region.neighbor_regions.each { |r|
      suffix = (r.name =~ /Locality$/ ? ' Locality' : (r.name =~ /Greater Area$/ ? ' Greater Area' : ''))
      name = (!base_name_changed.blank? ? region.name + suffix : r.name)
      set_params(region, name, r.size)
      update_neighbor_region(r, base_name_changed, base_polygon_changed )
    }

  end

  # Update a neighbor region
  def update_neighbor_region(region, base_name_changed, base_polygon_changed)
    geojson_polygons = []

    # Regenerate polygon json only if needs base regions polygon is changed
    if should_generate_polygon('update', base_polygon_changed)
      geojson_polygons = generate_polygon_geojson_from_base_region(region)
      raw_polygon = JSON.generate geojson_polygons
    end

    # Update neighbor region name if base region name is changed
    region.update! name: @name if (!base_name_changed.blank? && base_polygon_changed.blank?)

    # Update neighbor region polygon if base regions polygon is changed
    region.update! base_region_id: @base_region_id, name: @name, raw_polygon_json: raw_polygon, size: @radius if !base_polygon_changed.blank?

  end

  # Check if we should generate polygon for neighbor region
  def should_generate_polygon(action, base_polygon_changed=nil)
    if (!@base_lat.nil? && !@base_lng.nil?)
      return true if action == 'create'
      return true if action == 'update' && !base_polygon_changed.blank?
    end

    return false
  end

  # Generate polygon geojson from base regions polygon geojson
  def generate_polygon_geojson_from_base_region region
    geojson_polygons = []

    (min_dist, max_dist) = region.distance_from_point(@base_lat, @base_lng, @base_polygon_geojson)
    max_radius = max_dist * @radius

    (east, ne, north, nw, west, sw, south, se) = Utils.get_boundary_for_greater_area(@base_lat, @base_lng, max_radius)
    geojson_polygons = Utils.generate_polygon_geojson(east, ne, north, nw, west, sw, south, se)

    return geojson_polygons
  end



end

