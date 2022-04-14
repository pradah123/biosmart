require_relative './inaturalist/transformer.rb'
require_relative './schema/observation.rb'

module Types
  include Dry.Types()
end

module Source
  class Inaturalist
    extend Dry::Initializer

    API_URL = 'https://api.inaturalist.org/v1/observations'.freeze
    
    param :total_results, default: proc { nil }, reader: :private

    option :d1, reader: :private, type: Types::Strict::String
    option :d2, reader: :private, type: Types::Strict::String
    option :lat, reader: :private, type: Types::Coercible::Float
    option :lng, reader: :private, type: Types::Coercible::Float
    option :radius, reader: :private, type: Types::Coercible::Integer
    option :geo, default: proc { true }, reader: :private, type: Types::Strict::Bool
    option :order, default: proc { 'desc' }, reader: :private, type: Types::Strict::String
    option :order_by, default: proc { 'observed_on' }, reader: :private, type: Types::Strict::String
    option :per_page, default: proc { 200 }, reader: :private, type: Types::Strict::Integer
    option :iconic_taxa, optional: true, reader: :private, type: Types::Strict::String
    option :page, default: proc { 1 }, reader: :private, type: Types::Strict::Integer

    def get_params()
      params = Source::Inaturalist.dry_initializer.attributes(self)
      params.delete(:total_results)
      if iconic_taxa.present?
        params[:iconic_taxa] = iconic_taxa
      end

      return params
    end

    def increment_page()
        @page += 1
    end

    def done()
        return  !@total_results.nil? && 
                (@page * @per_page > @total_results)
    end

    def get_observations()
      biosmart_obs = []
      response = HTTParty.get(
        API_URL,
        query: get_params(),
        # debug_output: $stdout
      )
      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        @total_results = result[:total_results]
        t = Inaturalist::Transformer.new()
        result[:results].each do |inat_obs|
          transformed_obs = t.call(inat_obs)
          validation_result = Source::Schema::ObservationSchema.call(transformed_obs)
          if validation_result.failure?
            Delayed::Worker.logger.info "Source::Inaturalist.get_observations: #{inat_obs}"
            Delayed::Worker.logger.error 'Source::Inaturalist.get_observations: ' + 
              "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
            next
          end
          biosmart_obs.append(transformed_obs)
        end
      end

      return biosmart_obs
    end
  end
end
