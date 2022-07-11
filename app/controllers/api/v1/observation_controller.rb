module Api::V1
  class ObservationController < ApiController

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

    def get_map_observations obj
      j = {}
      j['observations'] = obj.nil? ? [] : obj.observations.map { |o| { lat: o.lat, lng: o.lng } }
      render_success j
    end

    def region
      get_map_observations Region.find_by_id params[:id]
    end  

    def participation
      get_map_observations Participation.find_by_id params[:id]
    end  

    def contest
      get_map_observations Contest.find_by_id params[:id]
    end

  end
end 
