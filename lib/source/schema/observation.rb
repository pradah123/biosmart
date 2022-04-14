require 'dry/schema'

module Source
  module Schema
    ObservationSchema = Dry::Schema.Params do
      required(:unique_id).filled(:string)
      required(:scientific_name).filled(:string)
      required(:accepted_name).filled(:string)
      required(:creator_name).filled(:string)
      required(:lat).filled(:float)
      required(:lng).filled(:float)
      required(:observed_at).filled(:string)
      required(:identifications_count).filled(:integer)
      optional(:image_link).maybe(:string)
      optional(:common_name).maybe(:string)
    end
  end
end
