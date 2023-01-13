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
        regions = ::Region.default_scoped
        if search_params.contest_id.present?
          contest = ::Contest.find_by_id(search_params.contest_id)
          return Failure('Invalid contest provided.') if contest.blank?
          regions = contest.regions
        end
        Success(regions.offset(search_params.offset)
               .limit(search_params.limit)
               .order(search_params.sort_by => search_params.sort_order))
      end
    end

    class Show
      include Service::Application

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        required(:region_id).filled(:integer, gt?: 0)
      end
      
      class Params < AppStruct::Pagination
        attribute? :region_id, Types::Params::Integer
      end

      def execute(params)
        show_params = Params.new(params)
        fetch_region(show_params.region_id)
      end

      private

      def fetch_region(region_id)
        region = ::Region.find_by_id(region_id)
        return Failure('Invalid region id provided.') if region.blank?
        Success(region)
      end
    end

    class SearchBySpecies
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination
        optional(:contest_id).filled(:integer, gt?: 0)
        optional(:page).filled(:integer, gt?: 0)
      end

      class Params < AppStruct::Pagination
        attribute? :contest_id, Types::Params::Integer
        attribute? :contest_filter, Types::Params::String
        attribute? :search_text, Types::Params::String
        attribute? :start_dt, Types::Params::String
        attribute? :end_dt, Types::Params::String
        attribute? :page, Types::Params::Integer
      end

      def execute(params)
        search_params = Params.new(params)
        if search_params.start_dt.present? &&
           search_params.end_dt.present? &&
           DateTime.parse(search_params.start_dt, "%Y-%m-%d") > DateTime.parse(search_params.end_dt, "%Y-%m-%d")
          return Failure('start_dt cannot be greater than end_dt.')
        end
        if search_params.search_text.present?
          fetch_regions_by_species(search_params)
        else
          fetch_regions(search_params)
        end
      end

      private

      def fetch_regions_by_species(search_params)
        searched_regions = regions_hash = regions = []
        taxonomy_ids = ::RegionsObservationsMatview.get_taxonomy_ids(search_text: search_params.search_text)
        if search_params.contest_id.present?
          contest_id = search_params.contest_id
        elsif search_params.contest_filter.present? && !search_params.contest_filter.blank?
          contest_id = search_params.contest_filter.to_i
        end
        regions = ::RegionsObservationsMatview.get_regions_by_species(search_text: search_params.search_text,
                                                                      contest_id: contest_id,
                                                                      start_dt: search_params.start_dt,
                                                                      end_dt: search_params.end_dt)

        regions.each do |r|
          region_id = r.id
          species_count = ::RegionsObservationsMatview.get_total_sightings_for_region(region_id: region_id,
                                                                                      taxonomy_ids: taxonomy_ids,
                                                                                      start_dt: search_params.start_dt,
                                                                                      end_dt: search_params.end_dt)
          regions_hash.push({ region: r,
                              total_sightings: species_count,
                              bioscore: r.bioscore })
        end
        sorted_regions = regions_hash.sort_by { |h| [h[:total_sightings], h[:bioscore]] }
                                     .reverse
                                     .map { |row| row[:region] }

        searched_regions = Kaminari.paginate_array(sorted_regions).page(search_params.page).per(20)
        Success(searched_regions)
      end

      def fetch_regions(search_params)
        if search_params.contest_id.present?
          contest_id = search_params.contest_id
        elsif search_params.contest_filter.present? && !search_params.contest_filter.blank?
          contest_id = search_params.contest_filter.to_i
        end
        contest_query = ''
        contest_query = "contests.id = #{contest_id}" if contest_id.present?
        regions = []
        regions = ::Region.joins(:contests)
                          .where(contest_query)
                          .where('contests.utc_starts_at < ? AND contests.last_submission_accepted_at > ?', Time.now, Time.now)
                          .where(status: 'online')
                          .distinct
                          .order('bioscore desc')
                          .page(search_params.page).per(20)
        Success(regions)
      end
    end

    class Sightings
      include Service::Application
      include Dry::Monads[:result, :do]

      # Schema to encapsulate parameter validation
      ValidationSchema = Dry::Schema.Params do
        extend AppSchema::Pagination
        optional(:region_id).filled(:integer, gt?: 0)
        optional(:get_property_sightings).filled(:string, included_in?: ['true', 'false'])
        optional(:get_locality_sightings).filled(:string, included_in?: ['true', 'false'])
        optional(:get_gr_sightings).filled(:string, included_in?: ['true', 'false'])
        optional(:get_total_sightings).filled(:string, included_in?: ['true', 'false'])
      end

      class Params < AppStruct::Pagination
        attribute? :region_id, Types::Params::Integer
        attribute? :search_text, Types::Params::String
        attribute? :start_dt, Types::Params::String
        attribute? :end_dt, Types::Params::String
        attribute? :get_property_sightings, Types::Params::String
        attribute? :get_locality_sightings, Types::Params::String
        attribute? :get_gr_sightings, Types::Params::String
        attribute? :get_total_sightings, Types::Params::String
      end

      def execute(params)
        search_params = Params.new(params)
        error_message = validate_parameters(search_params)
        return Failure(error_message) if error_message.present?

        taxonomy_ids = []
        if search_params.search_text.present?
          taxonomy_ids = ::RegionsObservationsMatview.get_taxonomy_ids(search_text: search_params.search_text)
        end
        region_id = search_params.region_id
        start_dt  = search_params.start_dt
        end_dt    = search_params.end_dt

        sightings_count = if search_params.get_property_sightings == "true"
                            fetch_property_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
                          elsif search_params.get_locality_sightings == "true"
                            fetch_locality_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
                          elsif search_params.get_gr_sightings == "true"
                            fetch_greater_region_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
                          else
                            fetch_sightings_count(search_params, taxonomy_ids)
                          end
        Success(sightings_count)
      end



      private

      def validate_parameters(search_params)
        error_message = ''
        if search_params.start_dt.present? &&
           search_params.end_dt.present? &&
           DateTime.parse(search_params.start_dt, "%Y-%m-%d") > DateTime.parse(search_params.end_dt, "%Y-%m-%d")
           error_message = 'start_dt cannot be greater than end_dt.'
        end
        region = ::Region.find_by_id(search_params.region_id)
        error_message = 'Invalid region id provided.' if region.blank?

        return error_message
      end

      def fetch_sightings_count(search_params, taxonomy_ids)
        region_id = search_params.region_id
        region = ::Region.find_by_id(region_id)
        return Failure('Invalid region id provided.') if region.blank?

        start_dt = search_params.start_dt
        end_dt = search_params.end_dt

        total_sightings_count = 0
        property_sightings_count       = fetch_property_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
        locality_sightings_count       = fetch_locality_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
        greater_region_sightings_count = fetch_greater_region_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)

        total_sightings_count = property_sightings_count + locality_sightings_count + greater_region_sightings_count
        if search_params.get_total_sightings == "true"
          return total_sightings_count
        else
          sightings_count = {}
          sightings_count = {
            region_id: region_id,
            property_sightings_count: property_sightings_count,
            locality_sightings_count: locality_sightings_count,
            greater_region_sightings_count: greater_region_sightings_count,
            total_sightings_count: total_sightings_count
          }
          return sightings_count
        end
      end

      def fetch_property_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
        property_sightings_count = 0
        Rails.logger.info("#{region_id}, #{taxonomy_ids}, #{start_dt},#{end_dt}")
        property_sightings_count = ::RegionsObservationsMatview.get_species_count(region_id: region_id,
                                                                                  taxonomy_ids: taxonomy_ids,
                                                                                  start_dt: start_dt,
                                                                                  end_dt: end_dt)
        return property_sightings_count
      end

      def fetch_locality_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
        locality_sightings_count = 0
        locality = ::Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
        if locality.present?
          locality_sightings_count = ::RegionsObservationsMatview.get_species_count(region_id: locality.id,
                                                                                    taxonomy_ids: taxonomy_ids,
                                                                                    start_dt: start_dt,
                                                                                    end_dt: end_dt)
        end
        return locality_sightings_count
      end

      def fetch_greater_region_sightings_count(region_id, taxonomy_ids, start_dt, end_dt)
        greater_region_sightings_count = 0
        greater_region = ::Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
        if greater_region.present?
          greater_region_sightings_count = ::RegionsObservationsMatview.get_species_count(region_id: greater_region.id,
                                                                                          taxonomy_ids: taxonomy_ids,
                                                                                          start_dt: start_dt,
                                                                                          end_dt: end_dt)
        end
        return greater_region_sightings_count
      end
    end
  end
end
