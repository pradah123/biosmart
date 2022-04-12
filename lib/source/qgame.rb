require_relative './qgame/transformer.rb'

module Types
  include Dry.Types()
end

module Source
  class QGame
    extend Dry::Initializer

    API_URL = 'https://api.questagame.com/api/sightings'.freeze
    
    param :data_source_id, reader: :private, type: Types::Coercible::Integer
    param :count, default: proc { 0 }, reader: :private

    option :start_dttm, reader: :private, type: Types::Strict::String
    option :end_dttm, reader: :private, type: Types::Strict::String
    option :limit, reader: :private, default: proc { 50 }, type: Types::Coercible::Integer
    option :offset, reader: :private, default: proc { 0 }, type: Types::Coercible::Integer
    option :multipolygon, reader: :private, type: Types::Strict::String
    option :category_ids, optional: true, reader: :private, type: Types::Strict::String

    def get_params()
      params = Source::QGame.dry_initializer.attributes(self)
      params.delete(:count)
      params.delete(:data_source_id)
      if category_ids.present?
        params[:category_ids] = category_ids
      end

      return params
    end
    
    def get_observations()
      biosmart_obs = []
      # response = HTTParty.get(
      #     'https://jsonkeeper.com/b/ZZU0'
      # )
      response = HTTParty.get(
        API_URL,
        query: get_params()
        # debug_output: $stdout
      )
      if response.success? && !response.body.nil?
        begin
          result = JSON.parse(response.body, symbolize_names: true)
          t = Source::QGame::Transformer.new()
          count = result.count
          biosmart_obs = result.map{|qgame_obs| 
            t.call(qgame_obs).merge({data_source_id: data_source_id})
          }
        rescue JSON::ParserError => e
          # Trello 37: Track json parse exception via Raygun.
          # Avoid moving to dead & failed queue
          # Raygun.track_exception(e)
        end
      end

      return biosmart_obs
    end

    def done()
        return count <= 0
    end

    def next_offset()
        offset += limit
    end
  end
end
