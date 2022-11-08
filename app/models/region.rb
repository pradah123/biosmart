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
  after_update :compute_neighboring_regions, if: -> {:saved_change_to_raw_polygon_json || :saved_change_to_name }
  after_update :update_neighboring_region, if: :saved_change_to_size

  #
  # the timezone of the centre point of the region is found using a google
  # api. this is used in working out the utc date times in this region for a contest
  #
  after_save :set_time_zone_from_polygon, if: :saved_change_to_raw_polygon_json
  after_save :set_slug, if: :saved_change_to_name

  #
  # polygon computations are required to decide if an observation lies inside this
  # region. geokit polygons are used to acheive this, and since they are reused 
  # many times, the geokit polygon objects are cached.
  #
  after_save :update_polygon_cache, :set_time_zone_from_polygon

  enum status: [:online, :offline, :deleted]

  paginates_per 25


  #
  # the slug is used to identify a region from its url.
  #

  def set_slug
    slug = name.blank? ? SecureRandom.hex(8) : name.downcase.gsub(/[^[:word:]\s]/, '').gsub(/ /, '-')
    slug += '1' if ['contest'].include?(slug) || Region.all.where(slug: slug).count > 0
    update_column :slug, slug
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
      if !size.present? && !base_region_id.present?
        # inaturalist subregion has no limit on the radius
        Subregion.create! data_source_id: DataSource.find_by_name('inaturalist').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil

        # ebird subregions have default 50 km max radius
        #Subregion.create! data_source_id: DataSource.find_by_name('ebird').id, region_id: self.id, raw_polygon_json: p.to_json

        # observation.org does not need a radius- but will use the observation_dot_org_id from the region
        Subregion.create! data_source_id: DataSource.find_by_name('observation.org').id, region_id: self.id, raw_polygon_json: '{}'

        # questagame does not need a radius- but will use polygon in multipolygon db query format
        Subregion.create! data_source_id: DataSource.find_by_name('qgame').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil

        # mushroom observer needs north, south, east, west
        Subregion.create! data_source_id: DataSource.find_by_name('mushroom_observer').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil

        # Naturespot needs north, south, east, west
        Subregion.create! data_source_id: DataSource.find_by_name('naturespot').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil
        
        # CitSci does not need a polygon- but will use the project_id from the params
        Subregion.create! data_source_id: DataSource.find_by_name('citsci').id, region_id: self.id, raw_polygon_json: '{}'

      end
      # gbif needs polygon
      Subregion.create! data_source_id: DataSource.find_by_name('gbif').id, region_id: self.id, raw_polygon_json: p.to_json, max_radius_km: nil

    end
  end

  # Add or update neighbor regions for the base region
  def compute_neighboring_regions
    return if size.present? || base_region_id.present?
    
    locality_size = get_neighboring_region(region_type: 'locality')&.size || 5
    greater_region_size = get_neighboring_region(region_type: 'greater_region')&.size || 12.5

    # Create or update locality
    nr_locality = NeighboringRegion.new(self, nil, locality_size)
    r_locality = nr_locality.get_region()
    # https://apidock.com/rails/ActiveRecord/Base/save
    r_locality.save

    # Create or update greater region
    nr_greater_region = NeighboringRegion.new(self, nil, greater_region_size)
    r_greater_region = nr_greater_region.get_region()
    r_greater_region.save

    # Fetch and store observations for greater region
    #GbifObservationsFetchJob.perform_later(greater_region_id: r_greater_region.id) if saved_change_to_raw_polygon_json
  end


  def update_neighboring_region()
    base_region = Region.find_by_id(self.base_region_id)
    nr = NeighboringRegion.new(base_region, self, saved_change_to_size[1])
    nr = nr.get_region()
    nr.save

    # Will add this later
    #GbifObservationsDeleteJob.perform_later(region_id: nr.id)
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
  def self.get_polygon_from_raw_polygon_json raw_polygon_json
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

  def get_bio_value
    avg_obs_score = Constant.find_by_name('average_observations_score')&.value || 20

    observations = GbifObservationsMatview.get_observations_for_region(region_id: self.id)
    bio_value =  observations.average(:bioscore)
    bio_value = avg_obs_score if !bio_value.present? || bio_value.zero?
    return bio_value
  end

  def get_region_scores
    region_scores = Hash.new([])
    region_scores[:total_vs_greater_region_observations_score] = get_regions_score(region_type: 'greater_region', score_type: 'observations_score').to_f
    region_scores[:total_vs_locality_observations_score]       = get_regions_score(region_type: 'locality', score_type: 'observations_score').to_f
    region_scores[:this_year_vs_total_observations_score]      = get_yearly_score(score_type: 'observations_score', num_years: 1).to_f
    region_scores[:last_2years_vs_total_observations_score]    = get_yearly_score(score_type: 'observations_score', num_years: 2).to_f

    region_scores[:total_vs_greater_region_species_score] = get_regions_score(region_type: 'greater_region', score_type: 'species_score').to_f
    region_scores[:total_vs_locality_species_score]       = get_regions_score(region_type: 'locality', score_type: 'species_score').to_f
    region_scores[:this_year_vs_total_species_score]      = get_yearly_score(score_type: 'species_score', num_years: 1).to_f
    region_scores[:last_2years_vs_total_species_score]    = get_yearly_score(score_type: 'species_score', num_years: 2).to_f

    region_scores[:total_vs_greater_region_activity_score] = get_regions_score(region_type: 'greater_region', score_type: 'people_score').to_f
    region_scores[:total_vs_locality_activity_score]       = get_regions_score(region_type: 'locality', score_type: 'people_score').to_f
    region_scores[:this_year_vs_total_activity_score]      = get_yearly_score(score_type: 'people_score', num_years: 1).to_f
    region_scores[:last_2years_vs_total_activity_score]    = get_yearly_score(score_type: 'people_score', num_years: 2).to_f

    constants = Constant.get_all_constants
    obs_count     = get_observations_count(include_gbif: true)
    species_count = get_species_count(include_gbif: true)
    people_count  = get_people_count(include_gbif: true)
    observations_per_species = species_count.positive? ? obs_count / species_count : 0
    observations_per_person  = people_count.positive? ? obs_count / people_count : 0

    region_scores[:bio_value] = obs_count.positive? ? self.get_bio_value.round(2) * constants[:average_observations_score_constant] : 0

    region_scores[:species_diversity_score] = (observations_per_species * constants[:observations_per_species_constant] +
                                              ((region_scores[:total_vs_locality_species_score] ) * constants[:locality_species_constant] +
                                              (region_scores[:total_vs_greater_region_species_score]) * constants[:greater_region_species_constant] +
                                              (region_scores[:this_year_vs_total_species_score]) * constants[:current_year_species_constant] +
                                              (region_scores[:last_2years_vs_total_species_score] ) * constants[:species_trend_constant]) / 100).round(2)
    bi_yearly_vs_total_species_score = region_scores[:last_2years_vs_total_species_score] / 100
    yearly_vs_total_species_score    = region_scores[:this_year_vs_total_species_score] / 100
    region_scores[:species_trend]    = (bi_yearly_vs_total_species_score.positive? ?
                                       ((yearly_vs_total_species_score - (bi_yearly_vs_total_species_score/2))/ (bi_yearly_vs_total_species_score/2)).round(2)
                                       : 0) * constants[:species_trend_constant]

    region_scores[:monitoring_score] = (((region_scores[:total_vs_locality_observations_score] ) * constants[:locality_observations_constant] +
                                       (region_scores[:total_vs_greater_region_observations_score]) * constants[:greater_region_observations_constant] +
                                       (region_scores[:this_year_vs_total_observations_score]) * constants[:current_year_observations_constant] +
                                       (region_scores[:last_2years_vs_total_observations_score] ) * constants[:observations_trend_constant]) / 100).round(2)
    bi_yearly_vs_total_obs_score     = region_scores[:last_2years_vs_total_observations_score] / 100
    yearly_vs_total_obs_score        = region_scores[:this_year_vs_total_observations_score] / 100
    region_scores[:monitoring_trend] = (bi_yearly_vs_total_obs_score.positive? ?
                                       ((yearly_vs_total_obs_score - (bi_yearly_vs_total_obs_score/2))/ (bi_yearly_vs_total_obs_score/2) ).round(2)
                                       : 0) * constants[:observations_trend_constant]

    region_scores[:community_score]   = (observations_per_person * constants[:observations_per_person_constant] +
                                        ((region_scores[:total_vs_locality_activity_score] ) * constants[:locality_people_constant] +
                                        (region_scores[:total_vs_greater_region_activity_score]) * constants[:greater_region_people_constant] +
                                        (region_scores[:this_year_vs_total_activity_score]) * constants[:current_year_people_constant] +
                                        (region_scores[:last_2years_vs_total_activity_score] ) * constants[:activity_trend_constant]) / 100).round(2)
    bi_yearly_vs_total_activity_score = region_scores[:last_2years_vs_total_activity_score] / 100
    yearly_vs_total_activity_score    = region_scores[:this_year_vs_total_activity_score] / 100
    region_scores[:community_trend]   = (bi_yearly_vs_total_activity_score.positive? ?
                                        ((yearly_vs_total_activity_score - (bi_yearly_vs_total_activity_score/2))/ (bi_yearly_vs_total_activity_score/2)).round(2)
                                        : 0) * constants[:activity_trend_constant]

    return region_scores
  end

  # This method returns all the species of greater region(ranked by count in descending order)
  # which are not found in the base region
  def get_undiscovered_species()
    unfound_species = []
    nr = get_neighboring_region(region_type: 'greater_region')
    return unfound_species if !nr.present?

    nr_top_species = nr.get_top_species().map{|row| row[0]}
    return unfound_species if nr_top_species.length <= 0

    unfound_species = nr_top_species - observations.where(scientific_name: nr_top_species).pluck(:scientific_name).uniq
  end

  rails_admin do
    list do
      field :id
      field :name          
      field :description
      field :raw_polygon_json
      field :created_at
      field :size
    end
    edit do 
      field :user
      field :status
      field :name
      field :slug
      field :size do
        visible do
          bindings[:object].base_region_id.present?
        end
      end
      field :description
      field :region_url
      field :population
      field :logo_image_url
      field :header_image_url
      field :raw_polygon_json
      field :observation_dot_org_id
      field :inaturalist_place_id
      field :citsci_project_id
      field :created_at
    end
    show do 
      field :id      
      field :user
      field :status
      field :name
      field :slug
      field :size
      field :description
      field :region_url
      field :population
      field :logo_image_url
      field :header_image_url
      field :raw_polygon_json
      field :observation_dot_org_id
      field :inaturalist_place_id
      field :citsci_project_id
      field :created_at
    end  
  end

end
