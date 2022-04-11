require_relative './observation_transformer.rb'
require_relative './auth.rb'
require_relative './models/observations_response.rb'

module ObservationOrg
  URL = 'https://observation.org/api/v1/locations/%s/observations'.freeze
  
  def self.get_observations(params)
    access_token = Auth.get_access_token()
    biosmart_obs = []
    if params[:location_id].blank?
      return biosmart_obs
    end
    response = HTTParty.get(
      URL % [params[:location_id]],
      query: params,
      headers: {
          'Authorization' => "Bearer #{access_token}"
      },
      # debug_output: $stdout
    )
    if response.success? && !response.body.nil?
      begin
        response_h = JSON.parse(response.body)
        # result = JSON.parse(response.body, symbolize_names: true)
        # t = Inaturalist::Transformer.new()
        # biosmart_obs = result[:results].map{|inat_obs| t.call(inat_obs)}
        response_h['next_page'] = response_h.delete 'next'
        response_o = ObservationOrg::Model::ObservationsResponse.new(response_h)
        t = ObservationOrg::Transformer.new()
        biosmart_obs = response_o.results.map{|obs_org_obs| t.call(obs_org_obs)}        
      rescue JSON::ParserError => e
        # Trello 37: Track json parse exception via Raygun.
        # Avoid moving to dead & failed queue
        # Raygun.track_exception(e)
      end
    end

    return biosmart_obs
  end
end
