# frozen_string_literal: true

require 'dry/validation'
require_relative './application'
require_relative '../structs/pagination'
require_relative '../schemas/pagination'

module Service
  module Participation
    class Base
      include Service::Application
      include Dry::Monads[:result, :do]

      def execute(params)
        get_participation(params.contest_id, params.region_id)
      end

      private

      def get_participation(contest_id, region_id)
        participation = ::Participation.where(contest_id: contest_id,
                                              region_id: region_id).first
        if participation.blank?
          return Failure("Invalid contest id (#{contest_id}) or region id (#{region_id}).")
        end
        Success(participation)
      end
    end

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
          all_participations = participations.where(contest_id: search_params.contest_id)
        end
        participations = all_participations.includes(:region)
                                           .offset(search_params.offset)
                                           .limit(search_params.limit)
                                           .order(search_params.sort_key => search_params.sort_order)
        participations_arr = []

        # Merge Participation and Region data
        participations.each do |p|
          region_hash = Hash.new([])
          p_hash = Hash.new([])

          region_hash = ::RegionSerializer.new(p.region).serializable_hash[:data][:attributes]
          p_hash = ::ParticipationSerializer.new(p).serializable_hash[:data][:attributes]
          region_hash.merge!(p_hash)
          participations_arr.push(region_hash)
        end

        # Need to calculate percentiles for species_diversity, monitoring and community scores and
        # merge them with regions' other data
        regions = []
        all_participations = ::Contest.find_by_id(search_params[:contest_id])&.participations
        all_participations.each do |p|
          regions.push(p.region)
        end
        scores = ::Region.merge_intermediate_scores_and_percentiles(regions: regions)
        participations_arr.each do |p|
          p_scores_hash = scores.detect{ |s| s[:id] == p[:id].to_i }
          p.merge!(p_scores_hash)
        end

        Success(participations_arr)
      end
    end
  end
end
