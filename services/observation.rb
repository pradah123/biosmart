# frozen_string_literal: true

require 'dry/validation'
require 'dry/monads'
require 'dry/monads/do'

require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Observation
    # Class to encapsulate fetching observations request
    class Fetch
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:sort_by).filled(:string, included_in?: ['observed_at'])
        optional(:sort_order).filled(:string, included_in?: ['asc', 'desc'])
      end
      
      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :sort_by, Types::Params::String.default('observed_at')
        attribute? :sort_order, Types::Params::String.default('desc')
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_observations(search_params)
      end

      private

      def fetch_observations(search_params)
        observations = ::Observation
        if search_params.contest_id.present? && search_params.region_id.present?
          Rails.logger.debug "===== Before get_participation_observations_relation ====="
          observations = yield get_participation_observations_relation(
            search_params.contest_id, 
            search_params.region_id
          )
          Rails.logger.debug "===== After get_participation_observations_relation ====="
        elsif search_params.contest_id.present?
          observations = yield get_contest_observations_relation(
            search_params.contest_id
          )
        elsif search_params.region_id.present?
          observations = yield get_region_observations_relation(
            search_params.region_id
          )
        end
        Success(observations.includes(:observation_images)
                            .offset(search_params.offset)
                            .limit(search_params.limit)
                            .order(search_params.sort_by => search_params.sort_order)
                            .all)
      end

      def get_region_observations_relation(region_id)
        Rails.logger.debug "get_region_observations_relation(#{region_id})"
        region = Region.find_by_id(region_id)
        return Failure("Invalid region id (#{region_id}).") if region.blank?
        Success(region.observations)
      end

      def get_contest_observations_relation(contest_id)
        Rails.logger.debug "get_contest_observations_relation(#{contest_id})"
        contest = Contest.find_by_id(contest_id)
        return Failure("Invalid contest id (#{contest_id}).") if contest.blank?
        Success(contest.observations)
      end

      def get_participation_observations_relation(contest_id, region_id)
        Rails.logger.debug "get_participation_observations_relation(#{contest_id}, #{region_id})"
        participation = Participation.where(contest_id: contest_id,
                                            region_id: region_id)
                                      .first
        if participation.blank?
          return Failure(
            "Invalid contest id (#{contest_id}) & region id (#{region_id})."
          )
        end
        return Success(participation.observations)
      end
    end
  end
end
