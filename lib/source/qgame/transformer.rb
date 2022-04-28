require_relative "../../common/transformer_functions.rb"

module Source
  class QGame
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.populate_species_details(hash)
        scientific_name = hash[:category_name]
        common_name = hash[:category_name]
        if hash[:species].present?
          species = hash[:species]
          if species[:sname].present?
            scientific_name = species[:sname]
          end
          if species[:cname].present?
            common_name = species[:cname]
          end
        end
        hash.merge({
          scientific_name: scientific_name,
          common_name: common_name,
          accepted_name: scientific_name
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions

      APP_ID = 'qgame'.freeze

      define! do
        deep_symbolize_keys
        map_value :id, -> v { "#{APP_ID}-#{v}" }
        rename_keys id: :unique_id
        populate_species_details()
        map_value :submitted_by_id, -> v { v.to_s }
        rename_keys submitted_by_id: :creator_id
        rename_keys submitted_by_name: :creator_name
        map_value :date, -> v { DateTime.parse(v).new_offset(0).strftime('%Y-%m-%d %H:%M') }
        rename_keys date: :observed_at
        map_value :expert_comments, -> v { v.count }
        rename_keys expert_comments: :identifications_count
        map_value :images, -> images do
          images&.map { |image| image[:original] } || []
        end
        rename_keys images: :image_urls
        accept_keys [
          :unique_id,
          :observed_at,
          :lat, 
          :lng,
          :scientific_name,
          :creator_id,
          :common_name,
          :creator_name,
          :image_urls,
          :accepted_name,
          :identifications_count
        ]                
      end
    end
  end
end
