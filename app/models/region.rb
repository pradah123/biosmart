class Region < ApplicationRecord
  belongs_to :user
  has_many :participations
  has_many :contests, through: :participations
  has_and_belongs_to_many :observations

  after_save :prepare_geokit_polygons, :assign_observations, if: :saved_change_to_raw_polygon_json

  enum status: [:online, :offline, :deleted]

  #validates :name, presence: true
  #validates :description, presence: true
  #validate :logo_present
  #validate :header_present




  def logo_present
    errors.add :logo_image, 'logo image or image url are required' if logo_image.blank? && logo_image_url.blank?
  end  

  def header_present
    errors.add :header_image, 'header image or image url are required' if header_image.blank? && header_image_url.blank?
  end  

  @polygons = []
  @lat_min = 0
  @lat_max = 0
  @lng_min = 0
  @lng_max = 0

  def prepare_geokit_polygons
    return if raw_polygon_json.blank?

=begin    
    # make polygon objects ahead of time, for use when deciding if an observation is in the region
    # work out the bounding box contaning all polygons too

    @polygons = []
    
#Rails.logger.info raw_polygon_json
#Rails.logger.info JSON.parse(raw_polygon_json)

    json_arr = JSON.parse raw_polygon_json

    if json_arr
      json_arr.each do |polygon|
        points = [] 
        #Rails.logger.info ">>>>>"
        #Rails.logger.info polygon     
        polygon.each do |p|
          points.push Geokit::LatLng.new(p['lat'], p['lng'])
        end
        #Rails.logger.info "%&%&%&%"
        #Rails.logger.info points      
        @polygons.push Geokit::Polygon.new(points)
      end
    end  
    #Rails.logger.info @polygons
=end    
  end  

  def assign_observations
    observations_in_box = Observation.where lat: (@lat_min..@lat_max), lng: (@lng_min..@lng_max)
    observations_in_region = []

    observations_in_box.each do |o|
      observations_in_region << o if region_contains(o.lat, o.lng)
    end

    observations.clear
    observations = observations_in_region

    participations.each do |p|
      p.assign_observations
    end  
  end

  def region_contains lat, lng
    @polygons.each { |p| return true if p.contains?( GEOkit::LatLng.new lat.to_s, lng.to_s ); }
    return false
  end

  def get_polygons
    @polygons
  end

  def self.get_geojson_from_osm relation_id
    coordinates = []

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

    Rails.logger.info coordinates.inspect
  end


=begin
  def format_for_api(params={})
    data = {
        id: id,
        name: name,
        description: description,
        header_image_url: header_image_url,
        logo_image_url: logo_image_url,
        region_url: region_url,
        refresh_interval_mins: refresh_interval_mins,
        updated_at: updated_at
    }
    if params[:polygon_format] == :geo_json
        data[:polygon] = RGeo::GeoJSON.encode(multi_polygon)
    end
    
    return data
  end
=end



end
