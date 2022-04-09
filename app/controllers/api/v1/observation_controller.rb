module Api::V1
  class ObservationController < ApiController

    def bulk_create
      render json: { status: 'fail', message: 'no data_source_name given' } if params[:data_source_name].nil?
      render json: { status: 'fail', message: "array of observations is required" } if params[:observations].nil?
      render json: { status: 'fail', message: "observations is not an array" } unless params[:observations].is_a?(Array)

      data_source = DataSource.find_by_name params[:data_source_name]
      render json: { status: 'error', message: "data_source_name must be one of: #{ DataSource.all.pluck(:name).join(',') }" } if data_source.nil?
      
      params[:observations].each do |obs|

      end  

      render_success
    end
      
  end
end 