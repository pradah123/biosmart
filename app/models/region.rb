class Region < ApplicationRecord
  include CountableStatistics
  
  belongs_to :user
  has_many :participations
  has_many :contests, through: :participations
  has_and_belongs_to_many :observations

  after_save :update_polygon_cache

  enum status: [:online, :deleted]

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










  def self.get_geojson_string_from_multipolygon multipolygon
    geojson_string = ''
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
    end
  end

end
