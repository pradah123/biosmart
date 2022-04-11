require_relative "../../common/transformer_functions.rb"

module ObservationOrg
    APP_ID = 'observation.org'.freeze
    module Functions
        extend Dry::Transformer::Registry
        import Dry::Transformer::ArrayTransformations
        import Dry::Transformer::HashTransformations

        def self.transform_photos(hash, photo_key)
            photos = []
            hash[photo_key].each_with_index do |photo, index|
                photos.append({
                    image_thumb_url: photo,
                    image_large_url: photo,
                    unique_id: "#{hash[:unique_id]}-#{index}",
                    observation_id: nil
                })
            end
            hash.merge(photos: photos)
        end
    end

    class Transformer < Dry::Transformer::Pipe
        import TransformerFunctions
        import Functions

        define! do
            add_json(:json)
            deep_symbolize_keys
            map_value :id, -> v { "#{APP_ID}-#{v}" }
            rename_keys id: :unique_id
            rename_keys number: :obs_count
            unwrap :point, [:coordinates]
            map_value :coordinates, -> v { {lat: v.first, lng: v.last} }                        
            unwrap :coordinates, [:lat, :lng]
            rename_keys accuracy: :location_accuracy
            unwrap :species_detail, [:scientific_name, :name]
            rename_keys scientific_name: :sname
            copy_keys sname: :clean_sname
            rename_keys name: :cname
            rename_keys user: :user_id
            unwrap :location_detail, [:name]
            rename_keys name: :loc_text
            convert_to_utc(:lat, :lng, :date, :time, :obs_dttm)
            add(:app_id, APP_ID)
            add(:identifications_count, 1)
            copy_keys photos: :photos_count
            map_value :photos_count, -> v { v.count }
            transform_photos(:photos)
            accept_keys [
                :unique_id,
                :obs_dttm,
                :obs_count,
                :lat, 
                :lng,
                :sname,
                :cname,
                :user_id,
                :loc_text,
                :location_accuracy,
                :photos_count,
                :app_id,
                :is_certain,
                :photos,
                :json,
                :clean_sname,
                :identifications_count
            ]                
        end
    end
end
