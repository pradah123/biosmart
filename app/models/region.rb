require_relative '../../lib/region/neighboring_region.rb'

class Region < ApplicationRecord
  include CountableStatistics
  
  scope :recent, -> { order created_at: :desc }
  scope :online, -> { where status: Region.statuses[:online] }
  scope :parent_region, -> { where parent_region_id: nil }

  belongs_to :user, optional: true

  #
  # parent regions may have no polygons themselves, but have many
  # child regions, referenced through the key parent_region_id.
  #
  # eg. a parent region may be australia, which has child regions, one for
  # each province. the provinces would each have the parent_region_id set to
  # the region id for australia.
  #

  belongs_to :parent_region, class_name: 'Region', optional: true
  has_many :child_regions, class_name: 'Region', foreign_key: 'parent_region_id'
  has_many :participations, dependent: :delete_all
  has_many :subregions, dependent: :delete_all
  has_many :neighboring_regions, class_name: 'Region', foreign_key: 'base_region_id', dependent: :delete_all
  has_many :contests, through: :participations
  has_and_belongs_to_many :observations
 
  #
  # subregions are used in fetching data when the region size is too large
  # for one api call to cover
  #
  after_create :compute_subregions, :set_lat_lng, :compute_neighboring_regions
  after_update :compute_subregions, :set_lat_lng, if: :saved_change_to_raw_polygon_json
  after_update :compute_neighboring_regions, if: -> {:saved_change_to_raw_polygon_json || :saved_change_to_name}

  #
  # the timezone of the centre point of the region is found using a google
  # api. this is used in working out the utc date times in this region for a contest
  #
  after_save :set_time_zone_from_polygon, if: :saved_change_to_raw_polygon_json

  #
  # polygon computations are required to decide if an observation lies inside this
  # region. geokit polygons are used to acheive this, and since they are reused 
  # many times, the geokit polygon objects are cached.
  #
  after_save :update_polygon_cache, :set_time_zone_from_polygon
  after_save :set_slug

  enum status: [:online, :offline, :deleted]

  paginates_per 25


  #
  # the slug is used to identify a region from its url.
  #

  def set_slug
    if slug.nil?
      slug = name.blank? ? SecureRandom.hex(8) : name.downcase.gsub(/[^[:word:]\s]/, '').gsub(/ /, '-')
      slug += '1' if ['contest'].include?(slug) || Region.all.where(slug: slug).count>0
      update_column :slug, slug
    end
  end
    
  def get_path
    "/#{slug}"
  end  

  def get_region_contest_path contest
    "/#{slug}/#{contest.slug}/"
  end  

  def get_child_region_polygons
    child_regions.map { |r| JSON.parse r.raw_polygon_json }.flatten.map { |p| p.to_hash }
  end  

  def self.get_all_regions
    arr = Region.where(base_region_id: nil).where.not(lat: nil, lng: nil).map { |r| { name: r.name, url: r.get_path, lat: r.lat, lng: r.lng } }
    Rails.logger.info arr
    arr
  end  


  
  def set_lat_lng
    #
    # get the centre of the polygons
    #

    polygons = JSON.parse raw_polygon_json
    lat_centre = 0
    lng_centre = 0
    n = 0
    polygons.each do |p|
      lng_centre += p['coordinates'].map { |c| c[0] }.sum
      lat_centre += p['coordinates'].map { |c| c[1] }.sum
      n += p['coordinates'].length
    end
    return if n==0
 
    lat_centre /= n
    lng_centre /= n

    update_column :lat, lat_centre
    update_column :lng, lng_centre
  end

  def set_time_zone_from_polygon
    #
    # https://developers.google.com/maps/documentation/timezone/get-started#maps_http_timezone-rb
    # use api from here to get the timezone offset of this lat,lng in minutes
    #

    unless self.lat.nil? || self.lng.nil?
      google_api_key = "AIzaSyBFT4VgTIfuHfrL1YYAdMIUEusxzx9jxAQ"
      url = "https://maps.googleapis.com/maps/api/timezone/json?location=#{self.lng}%2C#{self.lat}&timestamp=#{Time.now.to_i}&key=#{google_api_key}"
      offset_mins = 0
      begin
        response = HTTParty.get url
        response_json = JSON.parse response.body
        offset_mins = response_json['rawOffset']
        update_column :timezone_offset_mins, (offset_mins/60)
        participations.each { |p| p.set_start_and_end_times }
      rescue => e
        Rails.logger.error "google api failed for lat,lng = #{lat},#{lng}" 
      end
    end

  end





  def compute_subregions
    subregions.delete_all
    polygons = JSON.parse raw_polygon_json

    # 
    #  make subregions for all possible data sources- we only need to do this once
    #  and the data can be reused when required
    #
    #  for an object s of type Subregion, the query parameters can 
    #  be accessed at s.get_query_parameters
    #

    polygons.each do |p|
      # inaturalist subregion has no limit on the radius
      Subregion.create! data_source_id: DataSource.find_by_name('inaturalist').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil

      # ebird subregions have default 50 km max radius
      Subregion.create! data_source_id: DataSource.find_by_name('ebird').id, region_id: self.id, raw_polygon_json: p.to_json

      # observation.org does not need a radius- but will use the observation_dot_org_id from the region
      Subregion.create! data_source_id: DataSource.find_by_name('observation.org').id, region_id: self.id, raw_polygon_json: '{}'

      # questagame does not need a radius- but will use polygon in multipolygon db query format
      Subregion.create! data_source_id: DataSource.find_by_name('qgame').id, region_id: self.id, raw_polygon_json: p.to_json

      # mushroom observer needs north, south, east, west
      Subregion.create! data_source_id: DataSource.find_by_name('mushroom_observer').id, region_id: self.id, raw_polygon_json: p.to_json

      # gbif needs polygon
      Subregion.create! data_source_id: DataSource.find_by_name('gbif').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil

    end
  end

  # Add or update neighbor regions for the base region
  def compute_neighboring_regions
    return if size.present? || base_region_id.present?
    
    # Create or update locality
    nr_locality = NeighboringRegion.new(self, 2.5)
    r_locality = nr_locality.get_region()
    # https://apidock.com/rails/ActiveRecord/Base/save
    r_locality.save

    # Create or update greater region
    nr_greater_region = NeighboringRegion.new(self, 5)
    r_greater_region = nr_greater_region.get_region()
    r_greater_region.save

    # Fetch and store observations for greater region
    #GbifObservationsFetchJob.perform_later(greater_region_id: r_greater_region.id) if saved_change_to_raw_polygon_json
  end

  #
  #  polygon caching and computation functions,
  #  all based around geokit polygon objects.
  #

  @@polygons_cache = {}

  def update_polygon_cache
    get_geokit_polygons true
  end  

  def get_geokit_polygons update_polygons=false
    key = "r#{id}"

    if @@polygons_cache[key].nil? || update_polygons==true
      polygons = []
      begin
        json = JSON.parse raw_polygon_json
        if json
          json.each do |polygon|
            points = polygon['coordinates'].map { |c| Geokit::LatLng.new c[1], c[0] }
            polygons.push Geokit::Polygon.new(points)
          end
        end
      rescue
      end
      @@polygons_cache[key] = polygons
    end

    @@polygons_cache[key]
  end

  def contains? lat, lng
    get_geokit_polygons.each { |polygon| return true if polygon.contains?(Geokit::LatLng.new lat, lng) }
    return false    
  end

  # Conversion code from geojson polygon format to polygon db query format(wkt format).
  def get_polygon_from_raw_polygon_json raw_polygon_json
    polygon_geojson = JSON.parse raw_polygon_json
    polygon_geojson = [polygon_geojson] unless polygon_geojson.kind_of?(Array)

    polygon_strings = []
    polygon_geojson.each do |rpj|
      if rpj['coordinates'].present? && rpj['coordinates'][0].join != rpj['coordinates'][-1].join
        rpj['coordinates'].push rpj['coordinates'][0]
      end
      coordinates = rpj['coordinates'].map { |c| "#{c[0]} #{c[1]}" }.join ','
      polygon_strings.push "(#{ coordinates })"
    end

    "POLYGON(#{ polygon_strings.join ', ' })"
  end


  #
  # conversion code from geojson polygon format to multipolygon db query format.
  #

  def self.get_multipolygon_from_raw_polygon_json raw_polygon_json
    polygon_geojson = JSON.parse raw_polygon_json
    polygon_geojson = [polygon_geojson] unless polygon_geojson.kind_of?(Array)
    
    polygon_strings = []
    polygon_geojson.each do |rpj|
      rpj['coordinates'].push rpj['coordinates'][0] unless rpj['coordinates'].empty?
      coordinates = rpj['coordinates'].map { |c| "#{c[0]} #{c[1]}" }.join ','
      polygon_strings.push "((#{ coordinates }))"
    end

    "MULTIPOLYGON(#{ polygon_strings.join ', ' })"
  end

  def self.get_raw_polygon_json_string_from_multipolygon multipolygon
    polygons = multipolygon.gsub('MULTIPOLYGON((', '').gsub('))', '').split '('
    geojson_polygons = []

    polygons.each do |p|
      geojson = {}
      geojson['type'] = 'Polygon'
      geojson['coordinates'] = []

      parts = p.gsub(')', '').strip.split ','
      parts.each do |c|        
        coordinates = c.split ' '
        arr = [coordinates[0].strip.to_f, coordinates[1].strip.to_f]
        geojson['coordinates'].push arr
      end

      geojson_polygons.push geojson unless geojson['coordinates'].empty? 
    end

    JSON.generate geojson_polygons
  end


  def self.reset_datetimes
    Participation.all.each do |p|
      unless p.contest.nil?
        p.update_column :starts_at, p.contest.starts_at
        p.update_column :ends_at, p.contest.ends_at
        p.update_column :last_submission_accepted_at, p.contest.last_submission_accepted_at
      end  
    end

    Contest.all.each do |c|
      c.update_column :utc_starts_at, c.starts_at
      c.update_column :utc_ends_at, c.ends_at
    end

    Region.all.each do |r|
      r.set_time_zone_from_polygon
    end
  end    


  #
  # tmp functions used to circumvent the fact that
  # S3 image upload does not work.
  #

  def self.save_img str, id, name
    filename = "#{Rails.root}/public/region-#{id}-#{name}.png"
    i = str.index 'base64,'
    unless i.nil?
      data = str[i+7, str.length]
      data_decoded = Base64.decode64 data
      File.open(filename, "wb") do |f| 
        f.write data_decoded
      end
    end  
  end

  def save_to_file
    unless logo_image.nil?
      filename = "#{Rails.root}/public/region-#{id}-logo.png"
      i = logo_image.index 'base64,'
      unless i.nil?
        data = logo_image[i+7, logo_image.length]
        data_decoded = Base64.decode64 data
        File.open(filename, "wb") do |f| 
          f.write data_decoded
        end
      end
    end
    unless header_image.nil?
      filename = "#{Rails.root}/public/region-#{id}-header.png"
      i = header_image.index 'base64,'
      unless i.nil?
        data = header_image[i+7, header_image.length]
        data_decoded = Base64.decode64 data
        File.open(filename, "wb") do |f| 
          f.write data_decoded
        end
      end 
    end
  end  

  ## Convert raw_polygon_json text into json object
  def get_polygon_json
    if raw_polygon_json.nil?
      return nil
    end

    polygon_geojson = JSON.parse raw_polygon_json
    polygon_geojson = [polygon_geojson] unless polygon_geojson.kind_of?(Array)

    return polygon_geojson
  end


  ## Calculate minimum and maximum distance of region from a given coordinate
  def distance_from_point(lat, lng, polygon_geojson)
    min = max = nil
    if polygon_geojson.nil?
      return min, max
    end

    polygon_geojson.each do |polygon|
      if !polygon['coordinates'].nil?
        polygon['coordinates'].each.with_index { |c, i|
          p1 = Geokit::LatLng.new c[1] , c[0]
          p2 = Geokit::LatLng.new lat, lng
          dist = p1.distance_to(p2, units: :kms)
          if i == 0
            min = dist
            max = dist
          end
          if dist <= min
            min = dist
          end
          if dist > max
            max = dist
          end
        }
      end
    end
    return min, max

  end


  ### Find out whether given coordinates and region are within reach of given distance or not
  def is_region_near_to_point lat, lng, distance_km=50
    polygon_geojson = get_polygon_json
    if polygon_geojson.nil?
      return false
    end

    ## If given coordinate resides inside the polygon then return as true
    return true if contains? lat, lng

    (min_dist, max_dist) = distance_from_point(lat, lng, polygon_geojson)

    ## Return true, if distance between any polygon coordinate and given coordinate is
    ## less than or equal to required distance
    if !min_dist.nil? && min_dist.to_f <= distance_km
      return true
    else
      return false
    end
  end

  # bounds() -> [Geokit::Bounds]
  def bounds()
    bounds = []
    polygons = get_polygon_json()
    polygons.each do |polygon|
      min_lat, max_lat = polygon["coordinates"].map{ |c| c.last }.minmax
      min_lng, max_lng = polygon["coordinates"].map{ |c| c.first }.minmax
      bounds.push(
        Geokit::Bounds.new(
          # sw
          Geokit::LatLng.new(min_lat, min_lng), 
          # ne
          Geokit::LatLng.new(max_lat, max_lng)
        )
      )
    end

    return bounds
  end

  # scaled_bbox_geojson(with_multiplier:) -> Geokit::Bounds
  def scaled_bbox_geojson(with_multiplier:)
    scaled_polygons = []
    bounds().each do |bound|
      scaled_ne = bound.center.endpoint(
        bound.center.heading_to(bound.ne), 
        bound.center.distance_to(bound.ne, units: :kms) * with_multiplier, 
        units: :kms
      )
      scaled_sw = bound.center.endpoint(
        bound.center.heading_to(bound.sw), 
        bound.center.distance_to(bound.sw, units: :kms) * with_multiplier, 
        units: :kms
      )
      scaled_polygons.push({
        "type" => "Polygon",
        "coordinates" => [
          # nw
          [scaled_sw.lng, scaled_ne.lat],
          # ne
          [scaled_ne.lng, scaled_ne.lat],
          # se
          [scaled_ne.lng, scaled_sw.lat],
          # sw
          [scaled_sw.lng, scaled_sw.lat],
          # nw to close polygon
          [scaled_sw.lng, scaled_ne.lat]
        ]
      })
    end

    return scaled_polygons
  end

  ## Get largest neighboring region by size
  def get_neighboring_region(region_type: )
    nr = nil
    if neighboring_regions.present?
      nr = neighboring_regions.order("size").first if region_type == 'locality'
      nr = neighboring_regions.order("size").last if region_type == 'greater_region'
    end

    return nr
  end

  rails_admin do
    list do
      field :id
      field :name          
      field :description
      field :raw_polygon_json
      field :created_at      
    end
    edit do 
      field :user
      field :status
      field :name
      field :slug     
      field :description
      field :region_url
      field :population
      field :logo_image_url
      field :header_image_url
      field :raw_polygon_json
      field :observation_dot_org_id
      field :inaturalist_place_id
      field :created_at
    end
    show do 
      field :id      
      field :user
      field :status
      field :name
      field :slug     
      field :description
      field :region_url
      field :population
      field :logo_image_url
      field :header_image_url
      field :raw_polygon_json
      field :observation_dot_org_id
      field :inaturalist_place_id
      field :created_at
    end  
  end

end
