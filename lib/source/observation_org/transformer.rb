require_relative "../../common/transformer_functions.rb"

module Source
  class ObservationOrg
    class Transformer < Dry::Transformer::Pipe
      import TransformerFunctions
      
      APP_ID = 'observation.org'.freeze

      define! do
        deep_symbolize_keys
        map_value :id, -> v { "#{APP_ID}-#{v}" }
        rename_keys id: :unique_id
        unwrap :point, [:coordinates]
        map_value :coordinates, -> v { {lat: v.last, lng: v.first} }
        unwrap :coordinates, [:lat, :lng]
        unwrap :species_detail, [:scientific_name, :name]
        copy_keys scientific_name: :accepted_name
        rename_keys name: :common_name
        map_value :user, -> v { v.to_s }
        rename_keys user: :creator_id
        convert_to_utc(:lat, :lng, :date, :time, :observed_at)
        add(:identifications_count, 1)
        rename_keys photos: :image_urls
        accept_keys [
          :unique_id,
          :observed_at,
          :lat, 
          :lng,
          :scientific_name,
          :common_name,
          :creator_id,
          :image_urls,
          :accepted_name,
          :identifications_count
        ]                
      end
    end
  end
end
