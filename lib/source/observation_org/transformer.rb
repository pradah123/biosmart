require_relative "../../common/transformer_functions.rb"

module Source
  class ObservationOrg
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.extract_representative_image(hash, photo_key, image_key)
        image_link = nil
        if hash[photo_key].present? && hash[photo_key].count > 0
          image_link = hash[photo_key].first
        end
        hash.merge({
          image_key => image_link,
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions

      APP_ID = 'observation.org'.freeze

      define! do
        deep_symbolize_keys
        map_value :id, -> v { "#{APP_ID}-#{v}" }
        rename_keys id: :unique_id
        unwrap :point, [:coordinates]
        map_value :coordinates, -> v { {lat: v.first, lng: v.last} }                        
        unwrap :coordinates, [:lat, :lng]
        unwrap :species_detail, [:scientific_name, :name]
        copy_keys scientific_name: :accepted_name
        rename_keys name: :common_name
        map_value :user, -> v { "#{APP_ID}-#{v}" }
        rename_keys user: :creator_name
        convert_to_utc(:lat, :lng, :date, :time, :observed_at)
        add(:identifications_count, 1)
        extract_representative_image(:photos, :image_link)
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
