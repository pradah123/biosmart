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
        optional(:datasource_order).filled(:array)
        optional(:category).filled(:string)
        optional(:search_text).filled(:string)
        optional(:with_images).filled(:string, included_in?: ['true', 'false'])
      end
      
      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :sort_by, Types::Params::String.default('observed_at')
        attribute? :sort_order, Types::Params::String.default('desc')
        attribute? :datasource_order, Types::Params::Array
        attribute? :category, Types::Params::String
        attribute? :search_text, Types::Params::String
        attribute? :with_images, Types::Params::String.default('false')

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
            search_params.region_id,
            search_params.category,
            search_params.search_text
          )
        elsif search_params.contest_id.present?
          observations = yield get_contest_observations_relation(
            search_params.contest_id, search_params.category, search_params.search_text
          )
        elsif search_params.region_id.present?
          observations = yield get_region_observations_relation(
            search_params.region_id, search_params.category, search_params.search_text
          )
        end

        if search_params.with_images == 'true'
          observations = observations.includes(:observation_images)
                                    .includes(:data_source)
                                    .includes(:taxonomy)
                                    .has_images
                                    .offset(search_params.offset)
                                    .limit(search_params.limit)
                                    .order(search_params.sort_by => search_params.sort_order)
        else
          observations = observations.includes(:observation_images)
                                    .includes(:data_source)
                                    .includes(:taxonomy)
                                    .offset(search_params.offset)
                                    .limit(search_params.limit)
                                    .order(search_params.sort_by => search_params.sort_order)
        end
        if search_params.datasource_order.present?
          # https://guides.rubyonrails.org/active_record_querying.html#unscope
          observations = observations.unscope(:order)
          # https://edgeapi.rubyonrails.org/classes/ActiveRecord/QueryMethods.html#method-i-in_order_of
          observations = observations.sort_by_data_source(search_params.datasource_order)
        end
        Success(observations)
      end

      def get_region_observations_relation(region_id, category, search_text)
        Rails.logger.debug "get_region_observations_relation(#{region_id})"
        region = ::Region.where id: region_id
        return Failure("Invalid region id (#{region_id}).") if region.first.blank?

        (start_dt, end_dt) = region.first.get_date_range_for_report()

        observations = ::Observation.filter_observations(category: category, q: search_text, obj: region, start_dt: start_dt, end_dt:end_dt)

        Success(observations)
      end

      def get_contest_observations_relation(contest_id, category, search_text)
        Rails.logger.debug "get_contest_observations_relation(#{contest_id})"
        contest = ::Contest.find_by_id(contest_id)
        return Failure("Invalid contest id (#{contest_id}).") if contest.blank?
        observations = yield filter_observations(contest, category, search_text)
        Success(observations)
      end

      def get_participation_observations_relation(contest_id, region_id, category, search_text)
        participation = ::Participation.where(contest_id: contest_id, region_id: region_id).first
        if participation.blank?
          return Failure(
            "Invalid contest id (#{contest_id}) and region id (#{region_id})."
          )
        end
        observations = yield filter_observations(participation, category, search_text)

        return Success(observations)
      end

      def filter_observations(obj, category, search_text)
        if category.present?
          (rank_name, rank_value) = Utils.get_category_rank_name_and_value(category_name: category)
          Rails.logger.info "rank_name: #{rank_name}, rank_value: #{rank_value}"
          if rank_name.blank? || rank_value.blank?
            return Failure(
              "Invalid category '#{category}'."
            )
          end
        end
        if category.present? && search_text.present?
          observations = obj.observations.joins(:taxonomy).where("lower(taxonomies.#{rank_name}) = ?", rank_value.downcase).search(search_text)
        elsif category.present?
          observations = obj.observations.joins(:taxonomy).where("lower(taxonomies.#{rank_name}) = ?", rank_value.downcase)
        elsif search_text.present?
          observations = obj.observations.search(search_text)
        else
          observations = obj.observations
        end
        Success(observations)
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
        optional(:with_images).filled(:string, included_in?: ['true', 'false'])
        optional(:category).filled(:string)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :with_images, Types::Params::String
        attribute? :category, Types::Params::String
      end

      def execute(params)
        transformed_params = Params.new(params)
        fetch_top_species(transformed_params, params)
      end

      private

      def fetch_top_species(transformed_params, params)
        if transformed_params.contest_id.present? && transformed_params.region_id.present?
          result = Service::Participation::Base.call(transformed_params).to_result
        else
          return Failure(
            "Invalid contest id (#{transformed_params.contest_id}) or region id (#{transformed_params.region_id})."
          )
        end
        if transformed_params.category.present?
          (rank_name, rank_value) = Utils.get_category_rank_name_and_value(category_name: transformed_params.category)
          if rank_name.blank? || rank_value.blank?
            return Failure(
              "Invalid category '#{transformed_params.category}'."
            )
          end
        end
        if result&.success?
          top_species = []
          if transformed_params.with_images == 'true'
            top_species = ::ParticipationSpeciesMatview.get_top_species_with_images(
              participation_id: result.success.id,
              offset: transformed_params.offset,
              limit: transformed_params.limit,
              rank_name: rank_name,
              rank_value: rank_value
            )
          else
            top_species = ::ParticipationSpeciesMatview.get_top_species(
              participation_id: result.success.id,
              offset: transformed_params.offset,
              limit: transformed_params.limit,
              rank_name: rank_name,
              rank_value: rank_value
            )
          end
          return Success(top_species)
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

    class FetchUndiscoveredSpecies
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination

        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:with_images).filled(:string, included_in?: ['true', 'false'])
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :region_id, Types::Params::Integer
        attribute? :with_images, Types::Params::String
      end

      def execute(params)
        search_params = Params.new(params)
        fetch_undiscovered_species(search_params, params)
      end

      private

      def fetch_undiscovered_species(search_params, params)
        if search_params.contest_id.present? && search_params.region_id.present?
          result = Service::Participation::Base.call(search_params).to_result
          if result&.success?
            undiscovered_species = result.success.region.get_undiscovered_species(offset: search_params.offset, limit: search_params.limit, participant: result.success)
          else
            return Failure(
              "Invalid contest id (#{search_params.contest_id}) or region id (#{search_params.region_id})."
            )
          end
        elsif search_params.region_id.present?
          result = Service::Region::Show.call(params).to_result
          if result&.success?
            undiscovered_species = result.success.get_undiscovered_species(offset: search_params.offset, limit: search_params.limit)
          else
            return Failure(
              "Invalid region id (#{search_params.region_id})."
            )
          end
        else
          return Failure(
            "Invalid contest id (#{search_params.contest_id}) or region id (#{search_params.region_id})."
          )
        end
        Success(undiscovered_species)
      end
    end
  end
end
