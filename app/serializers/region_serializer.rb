class RegionSerializer
  include JSONAPI::Serializer
  attributes  :name, :description, :raw_polygon_json, :header_image_url, :logo_image_url, :status,
    :region_url, :population, :user_id, 
    :observations_count, :identifications_count, :people_count, :species_count, 
    :physical_health_score, :mental_health_score, :bioscore
end
