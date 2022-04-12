require_relative './inaturalist/transformer.rb'

module Types
  include Dry.Types()
end

module Source
  class Inaturalist
    extend Dry::Initializer

    API_URL = 'https://api.inaturalist.org/v1/observations'.freeze
    
    param :data_source_id, reader: :private, type: Types::Coercible::Integer
    param :total_results, default: proc { 0 }, reader: :private

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
      params.delete(:done)
      if iconic_taxa.present?
        params[:iconic_taxa] = iconic_taxa
      end

      return params
    end

    def total_pages()
      return (total_results.to_f / per_page.to_f).ceil
    end

    def get_observations()
      biosmart_obs = []
      response = HTTParty.get(
        API_URL,
        query: get_params(),
        # debug_output: $stdout
      )
      if response.success? && !response.body.nil?
        begin
          result = JSON.parse(response.body, symbolize_names: true)
          total_results = result[:total_results]
          t = Inaturalist::Transformer.new()
          biosmart_obs = result[:results].map{|inat_obs| 
            t.call(inat_obs).merge({data_source_id: data_source_id})
        }
        rescue JSON::ParserError => e
          # Trello 37: Track json parse exception via Raygun.
          # Avoid moving to dead & failed queue
          # Raygun.track_exception(e)
        end
      end

      return biosmart_obs
    end
  end
end
