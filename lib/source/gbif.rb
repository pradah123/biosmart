require_relative './gbif/transformer.rb'
require_relative './schema/observation.rb'

module Types
  include Dry.Types()
end

module Source
  class GBIF
    extend Dry::Initializer

    API_URL = 'https://api.gbif.org/v1/occurrence/search'.freeze
    
    param :count, default: proc { nil }, reader: :private

    option :dataset_key, reader: :private, type: Types::Strict::Array
    option :geometry, reader: :private, type: Types::Strict::String
    option :eventDate, reader: :private, type: Types::Strict::String
    option :offset, default: proc { 1 }, reader: :private, type: Types::Strict::Integer
    option :limit, default: proc { 300 }, reader: :private, type: Types::Strict::Integer


    DATASET_MAP = {
      '50c9509d-22c7-4a22-a47d-8c48425ef4a7' => 'inaturalist', 
      '8a863029-f435-446a-821e-275f4f641165' => 'observation.org',
      '4fa7b334-ce0d-4e88-aaae-2e0c138d049e' => 'ebird',
      'e3ce628e-9683-4af7-b7a9-47eef785d3bb' => 'qgame'
    }

    def self.get_dataset_keys()
      return DATASET_MAP.keys
    end

    def self.get_dataset_name(dataset_key)
      return DATASET_MAP[dataset_key]      
    end

    def get_params()
      params = Source::GBIF.dry_initializer.attributes(self)
      params.delete(:count)
      Delayed::Worker.logger.info "Source::GBIF.params: #{params}"
      
      return params
    end

    def increment_page()
        @offset += limit
    end

    def done()
      return  !@count.nil? && 
              (@offset > @count)    
    end

    def get_observations()
      biosmart_obs = []
      response = HTTParty.get(
        API_URL,
        query: get_params()        
      )
      if response.success? && !response.body.nil?
        result = JSON.parse(response.body, symbolize_names: true)
        @count = result[:count]

        t = Source::GBIF::Transformer.new()
        result[:results].each do |gbif_obs|
          ## Process data only if datasetkey matches with the required set
          if !Source::GBIF.get_dataset_name(gbif_obs[:datasetKey]).blank?
            transformed_obs = t.call(gbif_obs)
              
            if transformed_obs.present?
              validation_result = Source::Schema::ObservationSchema.call(transformed_obs)

              if validation_result.failure?
                Delayed::Worker.logger.info "Source::GBIF.get_observations: #{transformed_obs}"
                Delayed::Worker.logger.error 'Source::GBIF.get_observations: ' + 
                  "#{validation_result.errors.to_h.merge(unique_id: transformed_obs[:unique_id])}"
                next
              end
              biosmart_obs.append(transformed_obs)
            end
          end
        end
      else 
        Delayed::Worker.logger.info "Source::GBIF.get_observations: #{response}"
      end
      Delayed::Worker.logger.info "Source::GBIF.get_observations biosmart_obs count: #{biosmart_obs.length}"
      return biosmart_obs
    end
  end
end
