class RegionSerializer
  include JSONAPI::Serializer
  attributes :user_id, :name, :description, :raw_polygon_json, :region_url, :population, :header_image, :logo_image, :header_image_url, :logo_image_url, :status
end
