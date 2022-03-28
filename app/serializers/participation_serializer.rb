class ParticipationSerializer
  include JSONAPI::Serializer
  attributes :status, :region_id, :contest_id

  attribute :data_source_ids do |object|
    object.data_sources.pluck :id
  end
end
