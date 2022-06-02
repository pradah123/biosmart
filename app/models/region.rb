class Region < ApplicationRecord
  include CountableStatistics
  
  scope :recent, -> { order created_at: :desc }
  scope :online, -> { where status: Region.statuses[:online] }
  scope :parent_region, -> { where parent_region_id: nil }

  belongs_to :user
  belongs_to :parent_region, class_name: 'Region', optional: true
  has_many :child_regions, class_name: 'Region', foreign_key: 'parent_region_id'

  has_many :participations, dependent: :delete_all
  has_many :subregions, dependent: :delete_all
  has_many :contests, through: :participations
  has_and_belongs_to_many :observations
 
  after_create :compute_subregions 
  after_update :compute_subregions if :saved_change_to_raw_polygon_json
  after_save :set_time_zone_from_polygon, if: :saved_change_to_raw_polygon_json
  after_save :update_polygon_cache, :set_lat_lng, :set_time_zone_from_polygon

  enum status: [:online, :offline, :deleted]


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
    end
  end



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

  def self.get_multipolygon_from_raw_polygon_json raw_polygon_json
    polygon_geojson = JSON.parse raw_polygon_json
    #polygon_geojson = [polygon_geojson] unless polygon_geojson.kind_of?(Array)
    return 'MULTIPOLYGON(())' if polygon_geojson['coordinates'].nil?

    polygon_geojson.each do |rpj|
      rpj['coordinates'].push rpj['coordinates'][0] unless rpj['coordinates'].empty?
      coordinates = rpj['coordinates'].map { |c| "#{c[1]} #{c[0]}" }.join ', ' # check order
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

  def self.get_geojson_from_osm relation_id
    coordinates = []

=begin
    r = HTTParty.get "https://api.openstreetmap.org/api/0.6/relation/#{relation_id}.json"
    members = r['elements'][0]['members']
    Rails.logger.info "Got relationship, #{members.length} members"
  
    members.each do |m|
      if m['type']=='way'   
        rr = HTTParty.get "https://api.openstreetmap.org/api/0.6/way/#{m['ref']}.json"
        Rails.logger.info rr['elements'].inspect
        nodes = rr['elements'][0]['nodes']
        Rails.logger.info ">> Got way, #{nodes.length} nodes"

        nodes.each do |n|
          rrr = HTTParty.get "https://api.openstreetmap.org/api/0.6/node/#{n}.json" 
          Rails.logger.info ">>>> Got node #{rrr.body['elements'][0].inspect}"
          c = { lat: rrr.body['elements'][0]['lat'], lng: rrr.body['elements'][0]['lon'] }
          coordinates.push c
        end

      elsif m['type']=='node'
        rr = HTTParty.get "https://api.openstreetmap.org/api/0.6/node/#{n}.json"  
        c = { lat: rr.body['elements'][0]['lat'], lng: rr.body['elements'][0]['lon'] }
        coordinates.push c

      end 
    end
=end

    coordinates
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
