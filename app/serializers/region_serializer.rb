class RegionSerializer
  include JSONAPI::Serializer
  attributes :user_id, :name, :description, :raw_polygon_json, :bioscore, :region_url, :population, :header_image_url, :logo_image_url, :status
end
