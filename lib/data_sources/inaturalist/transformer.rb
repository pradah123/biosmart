# require 'dry-transformer'
# require_relative '../../../common/constants.rb'
require_relative "../../common/transformer_functions.rb"

module Inaturalist
    module Functions
        extend Dry::Transformer::Registry
        import Dry::Transformer::ArrayTransformations
        import Dry::Transformer::HashTransformations

        def self.transform_photos(hash, photo_key)
            photos = []
            hash[photo_key].each_with_index do |photo, index|
                photos.append({
                    id: photo[:id],
                    image_thumb_url: photo[:url].gsub("square", "medium"),
                    image_large_url: photo[:url].gsub("square", "large"),
                    license_code: photo[:license_code],
                    attribution: photo[:attribution],
                    unique_id: "#{hash[:unique_id]}-#{index}",
                    observation_id: nil
                })
            end
            hash.merge({
                photos: photos,
                photos_count: photos.count
            })
        end

        def self.add_obs_dttm(hash, key)
            dttm =  hash[:time_observed_at] || 
                    hash[:observed_on_string] || 
                    hash[:observed_on] || 
                    hash[:created_at]
            hash.merge({
                key => DateTime.parse(dttm).new_offset(0)
            })
        end
    end

    class Transformer < Dry::Transformer::Pipe
        import TransformerFunctions
        import Functions
        
        quality_level_dict = {
            "needs_id" => 0,
            "casual" => 5,
            "research" => 10
        }

        define! do
            add_json(:json)
            deep_symbolize_keys
            # transform :unique_id
            map_value :id, -> v { "inaturalist-#{v}" }
            rename_keys id: :unique_id
            # transform :sname, :cname & :clean_sname
            unwrap :taxon, [:name, :preferred_common_name]
            rename_keys name: :sname
            rename_keys preferred_common_name: :cname
            copy_keys sname: :clean_sname
            # transform :loc_text
            rename_keys place_guess: :loc_text
            # transform :obs_count
            add(:obs_count, 1)
            # transform :app_id
            add(:app_id, 'inaturalist')
            # transform :username & :user_id
            unwrap :user, [:login, :id]
            rename_keys login: :username
            rename_keys id: :user_id
            # transform :photos & :photos_count
            transform_photos(:photos)
            # transform :location_accuracy
            map_value :obscured, -> v { v ? 0 : 1 }
            rename_keys obscured: :location_accuracy
            # transform :quality_level
            map_value :quality_grade, -> v { quality_level_dict[v] }
            rename_keys quality_grade: :quality_level
            # transform :lat & :lng
            unwrap :geojson, [:coordinates]
            map_value :coordinates, -> v { {lat: v.last, lng: v.first} }
            unwrap :coordinates, [:lat, :lng]
            # transform :obs_dttm
            add_obs_dttm(:obs_dttm)
            accept_keys [
                :unique_id,
                :sname,
                :cname,
                :clean_sname,
                :loc_text,
                :obs_count,
                :app_id,
                :username,
                :user_id,
                :photos,
                :photos_count,
                :location_accuracy,
                :quality_level,
                :lat,
                :lng,
                :obs_dttm,
                :json,
                :identifications_count
            ]                
        end
    end
end
