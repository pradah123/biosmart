class ParticipationSerializer
  include JSONAPI::Serializer
  attributes :observations_count, :identifications_count,
  :people_count, :species_count, :bioscore, :mental_health_score, :physical_health_score

  ## Commenting below code as we are not using it anywhere in the project
  # attribute :data_source_ids do |object|
  #   object.data_sources.pluck :id
  # end

  attribute :top_species do  |object, params|
    if !params.blank? && params[:include_top_species] == true
      object.get_top_species(10).map { | species |
        {
          name:  species[0],
          count: species[1]
        }}
    end
  end
  attribute :top_observers do  |object, params|
    if !params.blank? && params[:include_top_people] == true
      object.get_top_people(10).map { | observers |
        {
          name:  observers[0],
          count: observers[1]
        }}
    end
  end
end
