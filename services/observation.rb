# frozen_string_literal: true

require 'dry/validation'
require 'dry/monads'
require 'dry/monads/do'

require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'
require_relative './participation'
require_relative './region'
require_relative './contest'

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
        Rails.logger.debug "fetch_observations(#{search_params.inspect})"
        observations = ::Observation.default_scoped
        if search_params.contest_id.present? && search_params.region_id.present?
          observations = yield get_participation_observations_relation(
            search_params.contest_id, 
            search_params.region_id
          )
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
                            .order(search_params.sort_by => search_params.sort_order))
      end

      def get_region_observations_relation(region_id)
        Rails.logger.debug "get_region_observations_relation(#{region_id})"
        region = ::Region.find_by_id(region_id)
        return Failure("Invalid region id (#{region_id}).") if region.blank?
        Success(region.observations)
      end

      def get_contest_observations_relation(contest_id)
        Rails.logger.debug "get_contest_observations_relation(#{contest_id})"
        contest = ::Contest.find_by_id(contest_id)
        return Failure("Invalid contest id (#{contest_id}).") if contest.blank?
        Success(contest.observations)
      end

      def get_participation_observations_relation(contest_id, region_id)
        participation = ::Participation.where(contest_id: contest_id, region_id: region_id).first
        if participation.blank?
          return Failure(
            "Invalid contest id (#{contest_id}) and region id (#{region_id})."
          )
        end
        return Success(participation.observations)
      end
    end

    class FetchSpecies
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:n).filled(:integer, gt?: 0)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :n, Types::Params::Integer
      end

      def execute(params)
        transformed_params = Params.new(params)
        fetch_top_species(transformed_params, params)
      end

      private

      def fetch_top_species(transformed_params, params)
        n = transformed_params.n.present? ? transformed_params.n : 25

        if transformed_params.contest_id.present? && transformed_params.region_id.present?
          result = Service::Participation::Base.call(transformed_params).to_result
        elsif transformed_params.contest_id.present?
          result = Service::Contest::Base.call(params).to_result
        elsif transformed_params.region_id.present?
          result = Service::Region::Show.call(params).to_result
        else
          return Failure(
            "Invalid contest id (#{transformed_params.contest_id}) or region id (#{transformed_params.region_id})."
          )
        end
        if result&.success?
          return Success(result.success.get_top_species(n))
        end
        if result&.failure?
          return Failure(result.failure)
        end
      end
    end

    class FetchPeople
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:n).filled(:integer, gt?: 0)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :n, Types::Params::Integer
      end

      def execute(params)
        transformed_params = Params.new(params)
        fetch_top_people(transformed_params, params)
      end

      private

      def fetch_top_people(transformed_params, params)
        n = transformed_params.n.present? ? transformed_params.n : 25

        if transformed_params.contest_id.present? && transformed_params.region_id.present?
          result = Service::Participation::Base.call(transformed_params).to_result
        elsif transformed_params.contest_id.present?
          result = Service::Contest::Base.call(params).to_result
        elsif transformed_params.region_id.present?
          result = Service::Region::Show.call(params).to_result
        else
          return Failure(
            "Invalid contest id (#{transformed_params.contest_id}) or region id (#{transformed_params.region_id})."
          )
        end
        if result&.success?
          return Success(result.success.get_top_people(n))
        end
        if result&.failure?
          return Failure(result.failure)
        end
      end

    end
  end
end
