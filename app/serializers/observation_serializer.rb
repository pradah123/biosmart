class ObservationSerializer
    include JSONAPI::Serializer
    attributes :scientific_name, :common_name, :lat, :lng

    attribute :scientific_name do |object|
        object.scientific_name.nil? ? '' : object.scientific_name
    end

    attribute :common_name do |object|
        object.common_name.nil? ? '' : object.common_name
    end

    attribute :observed_at do |object|
        object.observed_at_utc
    end

    attribute :creator_name do |object|
        object.creator_name.nil? ? '' : object.creator_name
    end

    attribute :image_urls do |object|
        object.observation_images.pluck(:url)
    end
end