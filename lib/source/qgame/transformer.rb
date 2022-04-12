require_relative "../../common/transformer_functions.rb"

module Source
  class QGame
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.extract_representative_image(hash, photo_key, image_key)
        image_link = nil
        if hash[photo_key].present? && hash[photo_key].count > 0
          photo = hash[photo_key].first
          image_link = photo[:main]
        end
        hash.merge({
          image_key => image_link,
        })
      end

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
        rename_keys submitted_by_name: :creator_name
        map_value :date, -> v { DateTime.parse(v).new_offset(0) }
        rename_keys date: :observed_at
        # convert_to_utc(:lat, :lng, :date, :time, :observed_at)
        map_value :expert_comments, -> v { v.count }
        rename_keys expert_comments: :identifications_count
        extract_representative_image(:images, :image_link)
        accept_keys [
          :unique_id,
          :observed_at,
          :lat, 
          :lng,
          :scientific_name,
          :common_name,
          :creator_name,
          :image_link,
          :accepted_name,
          :identifications_count
        ]                
      end
    end
  end
end
