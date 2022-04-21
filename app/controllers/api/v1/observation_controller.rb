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

      Rails.logger.info ">>>>>>>>>>>>>>>>>>>>>>>>>>> here"

      if params[:region_id] && params[:contest_id]
        obj = Participation.where contest_id: params[:contest_id], region_id: params[:region_id]
      elsif params[:region_id]
        obj = Region.where id: params[:region_id]
      elsif params[:contest_id]
        obj = Contest.where id: params[:contest_id]
      else
        obj = [Observation.all]
      end

Rails.logger.info obj.inspect

      observations = []
      unless obj.blank?
        Rails.logger.info obj.inspect
        observations = obj.first.observations.has_image.has_scientific_name.recent[params[:nstart].to_i...params[:nend].to_i]
        Rails.logger.info observations.inspect

        observations = observations.map { |obs| {
          scientific_name: obs.scientific_name, 
          creator_name: (obs.creator_name.nil? ? '' : obs.creator_name),
          observed_at: obs.observed_at.strftime('%Y-%m-%d %H:%M'),
          image_urls: obs.observation_images.pluck(:url)
        } }
      end  
      
      j = { 'observations': observations }
      render_success j
    end

  end
end 