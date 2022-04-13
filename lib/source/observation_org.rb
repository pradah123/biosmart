require_relative './observation_org/auth.rb'
require_relative './observation_org/transformer.rb'

module Types
  include Dry.Types()
end

module Source
  class ObservationOrg
    extend Dry::Initializer

    API_URL = 'https://observation.org/api/v1/locations/%s/observations'.freeze

    param :count, default: proc { 0 }, reader: :private

    option :date_after, reader: :private, type: Types::Strict::String
    option :date_before, reader: :private, type: Types::Strict::String
    option :limit, reader: :private, type: Types::Coercible::Integer
    option :offset, reader: :private, type: Types::Coercible::Integer
    option :location_id, reader: :private, type: Types::Coercible::Integer

    def get_params()
      params = Source::ObservationOrg.dry_initializer.attributes(self)
      params.delete(:count)
      params.delete(:location_id)
      
      return params
    end
    
    def get_observations()
      access_token = Source::ObservationOrg::Auth.get_access_token()
      biosmart_obs = []
      response = HTTParty.get(
        API_URL % [location_id],
        query: get_params(),
        headers: {
            'Authorization' => "Bearer #{access_token}"
        },
        # debug_output: $stdout
      )
      if response.success? && !response.body.nil?
        begin
          result = JSON.parse(response.body, symbolize_names: true)
          t = Source::ObservationOrg::Transformer.new()
          count = result[:count]
          biosmart_obs = result[:results].map{|obs_org_obs| t.call(obs_org_obs)}
        rescue JSON::ParserError => e
          # Trello 37: Track json parse exception via Raygun.
          # Avoid moving to dead & failed queue
          # Raygun.track_exception(e)
        end
      end

      return biosmart_obs
    end

    def done()
        return offset >= count
    end

    def next_offset()
        offset += limit
    end
  end
end
