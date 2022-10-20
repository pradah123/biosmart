# frozen_string_literal: true

require 'dry/validation'
require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Region
    # Class to encapsulate fetching sightings request
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
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_regions(search_params)
      end

      private

      def fetch_regions(search_params)
        regions = ::Region.not_deleted
        if search_params.contest_id.present?
          contest = Contest.find_by_id(search_params.contest_id)
          return Failure('Invalid contest provided.') if contest.blank?
          regions = contest.regions.not_deleted
        end
        Success(regions.offset(search_params.offset)
               .limit(search_params.limit)
               .order(search_params.sort_by => search_params.sort_order)
               .all)
      end
    end
  end
end
