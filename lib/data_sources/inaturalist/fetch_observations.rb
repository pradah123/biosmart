require_relative './transformer.rb'

module Inaturalist
  URL = 'https://api.inaturalist.org/v1/observations'

  def self.get_observations(params)
    biosmart_obs = []
    response = HTTParty.get(
      URL,
      query: params,
      # debug_output: $stdout
    )
    if response.success? && !response.body.nil?
      begin
        result = JSON.parse(response.body, symbolize_names: true)
        t = Inaturalist::Transformer.new()
        biosmart_obs = result[:results].map{|inat_obs| t.call(inat_obs)}
      rescue JSON::ParserError => e
        # Trello 37: Track json parse exception via Raygun.
        # Avoid moving to dead & failed queue
        # Raygun.track_exception(e)
      end
    end

    return biosmart_obs
  end
end
