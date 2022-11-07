class ObservationSerializer
    include JSONAPI::Serializer
    attributes :id, :lat, :lng, :identifications_count, :address, :creator_id, :bioscore

    attribute :creator_name do |object|
      object.creator_name.nil? ? '' : object.creator_name
    end
    attribute :scientific_name do |object|
        object.scientific_name.nil? ? '' : object.scientific_name
    end

    attribute :common_name do |object|
        object.common_name.nil? ? '' : object.common_name
    end

    attribute :accepted_name do |object|
      object.accepted_name.nil? ? '' : object.common_name
    end

    attribute :observed_at do |object|
      object.observed_at_utc
    end

    attribute :data_source do |object|
      DataSource.find_by_id(object.data_source_id).name
    end

    attribute :category do |object|
      # If data source of observation is questagame, check if scientific_name matches with any category name in _category_mapping.json
      # if matches then return scientific name as category name
      # else get category name from taxonomy details of associated taxonomy_id
      if DataSource.find_by_id(object.data_source_id).name == 'qgame' &&
         !Utils.get_category_rank_name_and_value(category_name: object.scientific_name).blank?
        object.scientific_name
      else
        Taxonomy.find_by_id(object.taxonomy_id)&.get_category_name&.first
      end
    end

    attribute :images do |object|
      object.observation_images
    end
end
