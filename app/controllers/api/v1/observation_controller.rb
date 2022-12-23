require './services/observation'

module Api::V1
  class ObservationController < ApiController

    def search
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Observation::Fetch.call(search_params) do |result|
        result.success do |observations|
          serialized_observations = []
          observations.each do |obs|
            serialized_observations.push(ObservationSerializer.new(obs).serializable_hash[:data][:attributes])
          end
          render json: serialized_observations
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def top_species
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Observation::FetchSpecies.call(search_params) do |result|
        result.success do |top_species|
          render json: { top_species: top_species }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def top_people
      search_params = params.to_unsafe_h.symbolize_keys
      Service::Observation::FetchPeople.call(search_params) do |result|
        result.success do |top_people|
          render json: { top_people: top_people }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def undiscovered_species
      search_params = params.to_unsafe_h.symbolize_keys

      Service::Observation::FetchUndiscoveredSpecies.call(search_params) do |result|
        result.success do |undiscovered_species|
          render json: { undiscovered_species: undiscovered_species }
        end
        result.failure do |message|
          raise ApiFail.new(message)
        end
      end
    end

    def bulk_create
      fail_message = nil
      fail_message = { status: 'fail', message: 'no data_source_name given' } if params[:data_source_name].nil?
      fail_message = { status: 'fail', message: "array of observations is required" } if params[:observations].nil?
      fail_message = { status: 'fail', message: "observations is not an array" } unless params[:observations].is_a?(Array)

      params[:observations].each do |obs|
        begin
          JSON.parse obs 
        rescue JSON::ParserError => e  
          fail_message = { status: 'fail', message: "observation data is not json: #{obs}" }
          break
        end
      end   

      unless fail_message.nil?
        render json: fail_message
        return
      end    

      data_source = DataSource.find_by_name params[:data_source_name]
      if data_source.nil?
        render json: { status: 'error', message: "data_source_name must be one of: #{ DataSource.all.pluck(:name).join(',') }" } 
        return
      end
        
      ObservationsCreateJob.perform_later data_source, params[:observations]
      render_success
    end
      
    def get_more
      nstart = params[:nstart]&.to_i || 0
      nend   = params[:nend]&.to_i || 24
      
      result = Observation.get_search_results params[:region_id], params[:contest_id], '', nstart, nend
      observations = result[:observations]

      observations = observations.map { |obs| {
        scientific_name: obs.scientific_name, 
        common_name: obs.common_name,
        creator_name: (obs.creator_name.nil? ? '' : obs.creator_name),
        observed_at: "#{ obs.observed_at.strftime '%Y-%m-%d %H:%M' } UTC",
        image_urls: obs.observation_images.pluck(:url),
        lat: obs.lat,
        lng: obs.lng
      } }
      
      j = { 'observations': observations }
      render_success j
    end

    def get_map_observations(obj, limit = nil)
      j = {}
      offset = 0
      if obj.is_a? Region
        observations = obj.observations.where("observed_at <= ?", Time.now).distinct
        # observations = Observation.get_observations_for_region(region_id: obj.id, include_gbif: true)
      elsif obj.is_a? Participation
        ends_at = obj.ends_at > Time.now ? Time.now : obj.ends_at
        observations = obj.region.observations.where("observed_at BETWEEN ? and ?", obj.starts_at, ends_at).distinct
      else
        ends_at = obj.first.ends_at > Time.now ? Time.now : obj.first.ends_at
        region_ids = obj.first.participations.map { |p|
          p.is_active? && !p.region.base_region_id.present? ? p.region.id : nil
        }.compact
        observations = Observation.joins(:observations_regions).where("observations_regions.region_id IN (?)", region_ids).where("observations.observed_at BETWEEN ? and ?", obj.first.starts_at, ends_at).distinct
      end
      limit = 5000 unless limit.present?
      observations = observations.recent.offset(offset).limit(limit)

      j['observations'] = obj.nil? ? [] : observations.map { |o|
         { id:  o.id,
           lat: o.lat,
           lng: o.lng
         } }

      render_success j
    end

    def get_observation_details obj
      j = {}
      j['observation'] = ObservationSerializer.new(obj).serializable_hash[:data][:attributes]

      render_success j
    end

    def data
      get_observation_details Observation.find_by_id params[:id]
    end

    def region
      get_map_observations Region.find_by_id params[:id]
    end  

    def participation
      get_map_observations((Participation.find_by_id params[:id]), params[:limit])
    end  

    def contest
      get_map_observations Contest.find_by_id params[:id]
    end

    def contest_region
      raise ApiFail.new("No contest id given") if params[:contest_id].blank?
      raise ApiFail.new("No region id given") if params[:region_id].blank?

      r = Region.find_by_id params[:region_id]
      c = Contest.find_by_id params[:contest_id]
      raise ApiFail.new("Region does not exist") unless r.present?
      raise ApiFail.new("Contest does not exist") unless c.present?

      p = r.participations&.find_by_contest_id c.id if r.present? && c.present?

      raise ApiFail.new("Region is not a participant in this contest") unless p.present?
      get_map_observations(p, params[:limit])
    end

    def get_species
      species = []
      if params[:term].present?
        search_text = params[:term]
        species = RegionsObservationsMatview.where("lower(scientific_name) like ?", "%#{search_text.downcase}%")
                                            .distinct
                                            .pluck(:scientific_name)
                                            .compact
        species += RegionsObservationsMatview.where("lower(common_name) like ?", "%#{search_text.downcase}%")
                                             .distinct
                                             .pluck(:common_name)
                                             .compact
      end
      render_success species.uniq.to_json
    end
  end
end 
