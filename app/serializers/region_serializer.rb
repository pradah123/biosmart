class RegionSerializer
  include JSONAPI::Serializer
  attributes :id, :name, :description, :header_image_url, :logo_image_url,
    :region_url, :lat, :lng, :observations_count, :identifications_count, :people_count,
    :species_count, :physical_health_score, :mental_health_score, :bioscore

  attribute :polygon do |object|
    object.get_polygon_json
  end
end
