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
      
  end
end 