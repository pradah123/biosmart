require_relative '../../lib/source/inaturalist.rb'
require_relative '../../lib/source/ebird.rb'
require_relative '../../lib/source/qgame.rb'
require_relative '../../lib/source/observation_org.rb'
require_relative '../../lib/source/mushroom_observer.rb'
require_relative '../../lib/source/gbif.rb'

class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
  has_many :api_request_logs

  #
  # this is where to control the query parameters format
  # for each data source
  #

  def get_query_parameters subregion
    return {} if subregion.nil?

    case name
    when 'inaturalist'
      {
        lat: subregion.lat,
        lng: subregion.lng,
        radius: subregion.radius_km.ceil,
        geo: true,
        order: "desc",
        order_by: "observed_on",
        per_page: 200,
        page: 1
      }

    when 'ebird'
      {
        lat: subregion.lat,
        lng: subregion.lng,
        dist: subregion.radius_km.ceil,
        sort: "date"
      }

    when 'qgame'
      multipolygon_wkt = Region.get_multipolygon_from_raw_polygon_json subregion.raw_polygon_json
      {
        multipolygon: multipolygon_wkt, 
        offset: 0, 
        limit: 50
      }

    when 'observation.org'
      if subregion.region.observation_dot_org_id.nil?
        {}
      else
        {
          location_id: (subregion.region.observation_dot_org_id), 
          offset: 0, 
          limit: 100
        }
      end
    when 'mushroom_observer'
      if subregion.region.raw_polygon_json.present?
        parsed_polygon = JSON.parse(subregion.raw_polygon_json)
        west, east, south, north = Utils.get_bounding_box(parsed_polygon)
        return {
          north: north,
          south: south,
          east: east,
          west: west
        }
      else
        raise ArgumentError.new("Polygon does not exists for region #{subregion.region.id}")
      end
    when 'gbif'
      if subregion.raw_polygon_json.present?
        polygon_wkt = subregion.get_polygon_from_raw_polygon_json(subregion.raw_polygon_json)
        return {
          offset: 0,
          limit: 300,
          geometry: polygon_wkt
        }
      else
        raise ArgumentError.new("Polygon does not exists for region #{subregion.id}")
      end
    else
      {}
    end     
  end


  def fetch_observations region, starts_at, ends_at
    if name == 'gbif'
      fetch_gbif region, starts_at, ends_at ## We can directly fetch for whole region for gbif
    else
      subregions = Subregion.where(region_id: region.id, data_source_id: id)
      subregions.each do |sr|
        case name
        when 'inaturalist'
          fetch_inat sr, starts_at, ends_at
        when 'ebird'
          fetch_ebird sr, starts_at, ends_at
        when 'qgame'
          fetch_qgame sr, starts_at, ends_at
        when 'observation.org'
          fetch_observations_dot_org sr, starts_at, ends_at
        when 'mushroom_observer'
          fetch_mushroom_observer sr, starts_at, ends_at
        else
          self.send "fetch_#{name}", region # PRW: if you have the explicit case statements, we don't need this
        end
      end
    end
  end


  def fetch_gbif region, starts_at, ends_at
    Delayed::Worker.logger.info "fetch_observations_gbif(#{region.id}, #{starts_at}, #{ends_at})"

    begin
      params = get_query_parameters region
      params[:eventDate] = "#{starts_at.strftime('%Y-%m-%d')},#{ends_at.strftime('%Y-%m-%d')}"
      params[:dataset_key] = Source::GBIF.get_dataset_keys()

      gbif = ::Source::GBIF.new(**params)
      loop do
          observations = gbif.get_observations() || []
          observations.each{ |o|
            geokit_point = Geokit::LatLng.new o[:lat], o[:lng]
            region.get_geokit_polygons.each do |polygon|
              if polygon.contains?(geokit_point)
                ObservationsCreateJob.perform_later self, [o]
              end
            end
          }
          gbif.increment_page()
          break if gbif.done()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_gbif_observer: #{e.full_message}"
    end
  end

  def fetch_mushroom_observer subregion, starts_at, ends_at
    Delayed::Worker.logger.info "fetch_mushroom_observer(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:date] = "#{starts_at.strftime('%Y%m%d')}-#{ends_at.strftime('%Y%m%d')}"
      mushroom_observer = ::Source::MushroomObserver.new(**params)
      loop do                
          observations = mushroom_observer.get_observations() || []
          observations.each{ |o|
            if subregion.contains? o[:lat], o[:lng]
              ObservationsCreateJob.perform_later self, [o]
            end
          }
          mushroom_observer.increment_page()
          break if mushroom_observer.done()
      end
    rescue => e
      Delayed::Worker.logger.error "fetch_mushroom_observer: #{e.full_message}"
    end
  end

  def fetch_observations_dot_org subregion, starts_at, ends_at
    # fetch logic here
    Delayed::Worker.logger.info "fetch_observations_dot_org(#{subregion.id}, #{starts_at}, #{ends_at})"

# Peter: we need the begin-rescue around the api call inside the function, not 
# around the creation job. otherwise we can't get the correct error messages on the creation
# of observations

    begin
      params = get_query_parameters subregion
      params[:date_after] = starts_at.strftime('%F')
      params[:date_before] = ends_at.strftime('%F')
      ob_org = ::Source::ObservationOrg.new(**params)
      loop do                
          observations = ob_org.get_observations() || []

          observations.each{ |o|
            if subregion.region.contains? o[:lat], o[:lng]
              ObservationsCreateJob.perform_later self, [o]
            end
          }
          break if ob_org.done()
          ob_org.increment_offset()
      end
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"      
    end
  end 

  def fetch_inat subregion, starts_at, ends_at # PRW: we should change this to fetch_inaturalist to be consistent
    # fetch logic here
    Delayed::Worker.logger.info "fetch_inat(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:d1] = starts_at.strftime('%F')
      params[:d2] = ends_at.strftime('%F')
      inat = ::Source::Inaturalist.new(**params)
      loop do
        break if inat.done()
        observations = inat.get_observations() || []

        observations.each{ |o|
          if subregion.region.contains? o[:lat], o[:lng]
            ObservationsCreateJob.perform_later self, [o]
          end
        }
        inat.increment_page()
      end
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"
    end
  end 

  def fetch_ebird subregion, starts_at, ends_at
    # fetch logic here
    Delayed::Worker.logger.info "fetch_ebird(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:back] = (Time.now - starts_at).to_i / (24 * 60 * 60)
      params[:back] = 30 if params[:back] > 30
      ebird = ::Source::Ebird.new(**params)
      observations = ebird.get_observations() || []

      observations.each { |o|
        if subregion.region.contains? o[:lat], o[:lng]
          ObservationsCreateJob.perform_later self, [o]
        end
      }
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"
    end
  end

  def fetch_qgame subregion, starts_at, ends_at
    # fetch logic here
    Delayed::Worker.logger.info "fetch_qgame(#{subregion.id}, #{starts_at}, #{ends_at})"
    begin
      params = get_query_parameters subregion
      params[:start_dttm] = starts_at.strftime('%F')
      params[:end_dttm] = ends_at.strftime('%F')
      qgame = ::Source::QGame.new(**params)    
      loop do      
        break if qgame.done()
        observations = qgame.get_observations() || []

        observations.each { |o|
          if subregion.region.contains? o[:lat], o[:lng]
            ObservationsCreateJob.perform_later self, [o]
          end
        }
        qgame.increment_offset()
      end
    rescue => e
      Rails.logger.error "fetch_observations_dot_org: #{e.full_message}"
    end
  end 
  
  rails_admin do
    list do
      field :id
      field :name
      field :created_at              
    end
    edit do
      field :name
    end
    show do
      field :id
      field :name
      field :created_at
    end
  end 

end
