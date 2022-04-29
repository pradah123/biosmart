require_relative "../../common/transformer_functions.rb"

module Source
  class Inaturalist
    module Functions
      extend Dry::Transformer::Registry
      import Dry::Transformer::ArrayTransformations
      import Dry::Transformer::HashTransformations

      def self.add_obs_dttm(hash, key)
        dttm =  hash[:time_observed_at] || 
                hash[:observed_on_string] || 
                hash[:observed_on] || 
                hash[:created_at]
        hash.merge({
          key => DateTime.parse(dttm).new_offset(0).strftime('%Y-%m-%d %H:%M')
        })
      end
    end

    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      import Functions
        
      define! do
        deep_symbolize_keys
        # transform :unique_id
        map_value :id, -> v { "inaturalist-#{v}" }
        rename_keys id: :unique_id
        # transform :sname, :cname & :clean_sname
        unwrap :taxon, [:name, :preferred_common_name]
        rename_keys name: :scientific_name
        rename_keys preferred_common_name: :common_name
        copy_keys scientific_name: :accepted_name
        # transform :username & :user_id
        unwrap :user, [:login, :id]
        map_value :id, -> v { v.to_s }
        rename_keys id: :creator_id
        rename_keys login: :creator_name
        # transform :photos & :photos_count
        map_value :photos, -> images do
          images&.map { |image| image[:url]&.gsub("square", "large") } || []
        end
        rename_keys photos: :image_urls
        # transform :lat & :lng
        unwrap :geojson, [:coordinates]
        map_value :coordinates, -> v { {lat: v.last, lng: v.first} }
        unwrap :coordinates, [:lat, :lng]
        # transform :obs_dttm
        add_obs_dttm(:observed_at)
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
