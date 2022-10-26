# frozen_string_literal: true

require 'dry/validation'
require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Participation
    # Class to encapsulate fetching participations request
    class Fetch
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:sort_by).filled(:string, included_in?: ['id', 'bioscore'])
        optional(:sort_order).filled(:string, included_in?: ['asc', 'desc'])
      end
      
      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :sort_by, Types::Params::String.default('id')
        attribute? :sort_order, Types::Params::String.default('asc')

        def sort_key
          # Bioscore is not populated in participation model
          # If sort by bioscore, use corresponding region's bioscore
          sort_by == 'bioscore' ? "regions.bioscore" : sort_by
        end
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_participations(search_params)
      end

      private

      def fetch_participations(search_params)
        participations = ::Participation.default_scoped
        if search_params.contest_id.present?
          participations = participations.where(contest_id: search_params.contest_id)
        end
        Success(participations.includes(:region)
                              .offset(search_params.offset)
                              .limit(search_params.limit)
                              .order(search_params.sort_key => search_params.sort_order))
      end
    end
  end
end
