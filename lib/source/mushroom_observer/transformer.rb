require_relative "../../common/transformer_functions.rb"

module Source
  class MushroomObserver
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.populate_identifications_count(hash)
        identifications_count = hash[:votes].count || 0
        if identifications_count < 1 && hash[:scientific_name].present?
          identifications_count = 1
        end
        hash.merge({
          identifications_count: identifications_count
        })
      end

      def self.populate_images(hash)
        images = hash[:images] || [hash[:primary_image]] || []
        image_urls = images.map { |image| image[:original_url] }
        hash.merge({
          image_urls: image_urls
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions
        
      define! do
        deep_symbolize_keys
        # transform :unique_id
        map_value :id, -> v { "mo-#{v}" }
        rename_keys id: :unique_id
        # transform :sname, :cname & :clean_sname
        unwrap :consensus, [:name]
        rename_keys name: :scientific_name
        copy_keys scientific_name: :accepted_name
        # transform :username & :user_id
        unwrap :owner, [:legal_name, :id]
        map_value :id, -> v { v.to_s }
        rename_keys id: :creator_id
        rename_keys legal_name: :creator_name
        # transform :photos & :photos_count
        populate_images()
        # transform :lat & :lng
        rename_keys latitude: :lat
        rename_keys longitude: :lng
        # transform :obs_dttm
        rename_keys date: :observed_at
        populate_identifications_count()
        accept_keys [
          :unique_id,
          :scientific_name,
          :common_name,
          :accepted_name,
          :creator_id,
          :creator_name,
          :image_urls,
          :lat,
          :lng,
          :observed_at,
          :identifications_count
        ]                
      end
    end    
  end
end
