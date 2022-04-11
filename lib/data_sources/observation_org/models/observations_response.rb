module Types
    include Dry.Types()
end

module ObservationOrg
    module Model
        class ObservationsResponse < Dry::Struct
            transform_keys(&:to_sym)

            attribute :next_page, Types::String.optional
            attribute :results, Types::Array.optional
            attribute :count, Types::Integer.optional
        end
    end
end
