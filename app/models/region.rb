class Region < ApplicationRecord
  include CountableStatistics
  
  belongs_to :user
  has_many :participations
  has_many :subregions
  has_many :contests, through: :participations
  has_and_belongs_to_many :observations

  after_save :update_polygon_cache, :set_time_zone_from_polygon
  after_create :compute_subregions 
  after_update :compute_subregions if :saved_change_to_raw_polygon_json
  after_save :set_time_zone_from_polygon, if: :saved_change_to_raw_polygon_json

  enum status: [:online, :deleted]


  def get_slug
    name.blank? ? '' : name.downcase.gsub(/[^[:word:]\s]/, '').gsub(/ /, '-')
  end
    
  def get_path
    "/regions/#{id}/#{ get_slug }"
  end  

  def get_region_contest_path contest
    "/regions/#{id}/contests/#{ contest.id }/#{ contest.get_slug }/#{ get_slug }"
  end  



  def set_time_zone_from_polygon
    polygons = JSON.parse raw_polygon_json

    #
    # get the centre of the polygons
    #

    lat_centre = 0
    lng_centre = 0
    n = 0
    polygons.each do |p|
      lat_centre += p['coordinates'].map { |c| c[0] }.sum
      lng_centre += p['coordinates'].map { |c| c[1] }.sum
      n += p['coordinates'].length
    end
    return if n==0
 
    lat_centre /= n
    lng_centre /= n

    #
    # https://developers.google.com/maps/documentation/timezone/get-started#maps_http_timezone-rb
    # use api from here to get the timezone offset of this lat,lng in minutes
    #

    #google_api_key = "AIzaSyDUs2kqzzJeESUQuPKj5LlNQJ1K1PkqiFg"
    google_api_key = "AIzaSyBFT4VgTIfuHfrL1YYAdMIUEusxzx9jxAQ"
    url = "https://maps.googleapis.com/maps/api/timezone/json?location=#{lng_centre}%2C#{lat_centre}&timestamp=#{Time.now.to_i}&key=#{google_api_key}"
    offset_mins = 0
    begin
      response = HTTParty.get url
      response_json = JSON.parse response.body
      offset_mins = response_json['rawOffset']
    rescue => e
      Rails.logger.error "google api failed for lat,lng = #{lat_centre},#{lng_centre}" 
    end    

    update_column :timezone_offset_mins, offset_mins
    participations.each { |p| p.set_start_and_end_times }
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
    get_geokit_polygons.each { |polygon|
      return true if polygon.contains?(Geokit::LatLng.new lat, lng)
    }
    return false    
  end

  def self.get_multipolygon_from_raw_polygon_json_string raw_polygon_json_string 
    polygon_geojson = JSON.parse raw_polygon_json_string 

    polygon_strings = []
    polygon_geojson.each do |rpj|
      rpj['coordinates'].push rpj['coordinates'][0] unless rpj['coordinates'].empty?
      coordinates = rpj['coordinates'].map { |c| "#{c['lng']} #{c['lat']}" }.join ', '
      polygon_strings.push "((#{ coordinates }))"
    end

    "MULTIPOLYGON( #{ polygon_strings.join ', ' } )"
  end

  def self.get_raw_polygon_json_string_from_multipolygon multipolygon
   
    polygons = multipolygon.gsub('MULTIPOLYGON((', '').gsub('))', '').split '('

    geojson = {}
    geojson['type'] = 'Polygon'
    geojson['coordinates'] = []

    polygons.each do |p|
      Rails.logger.info ">>>>"
      Rails.logger.info p
      parts = p.gsub(')', '').strip.split ','
      parts.each do |c|
        Rails.logger.info c
        coordinates = c.split ' '
        Rails.logger.info coordinates
        arr = [coordinates[0].to_f, coordinates[1].to_f]
        Rails.logger.info arr
        Rails.logger.info "\n\n"
        geojson['coordinates'].push arr
      end  
    end  
    
    Rails.logger.info geojson

    JSON.generate geojson
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
  end

end
