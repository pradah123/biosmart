class CountController < ApplicationController
    def observations_count
        obs_count_query = Observation.where(deleted_at: nil)
        if params[:d1].present? && params[:d2].present?
            d1 = DateTime.parse(params[:d1])
            d2 = DateTime.parse(params[:d2])
            obs_count_query = obs_count_query.where(obs_dttm: d1..d2)
        end
        obs_count = obs_count_query.count(:id)
        render  json: {count: obs_count}, 
                status: :ok
    end

    def identifications_count
        id_count_query = Observation.where(deleted_at: nil)
        if params[:d1].present? && params[:d2].present?
            d1 = DateTime.parse(params[:d1])
            d2 = DateTime.parse(params[:d2])
            id_count_query = id_count_query.where(obs_dttm: d1..d2)
        end
        id_count = id_count_query.sum(:identifications_count)
        render  json: {count: id_count}, 
                status: :ok
    end

    def species_count
        species_count_query = Observation.where(
            'clean_sname IS NOT NULL AND deleted_at IS NULL'
        )
        if params[:d1].present? && params[:d2].present?
            d1 = DateTime.parse(params[:d1])
            d2 = DateTime.parse(params[:d2])
            species_count_query = species_count_query.where(obs_dttm: d1..d2)
        end
        species_count = species_count_query.distinct.count(:clean_sname)
        render  json: {count: species_count}, 
                status: :ok
    end

    def participants_count
        participants_count_query = Observation.where(
            'user_id IS NOT NULL AND deleted_at IS NULL'
        )
        if params[:d1].present? && params[:d2].present?
            d1 = DateTime.parse(params[:d1])
            d2 = DateTime.parse(params[:d2])
            participants_count_query = participants_count_query.where(obs_dttm: d1..d2)
        end
        participants_count = participants_count_query.distinct.count(:user_id)
        render  json: {count: participants_count}, 
                status: :ok
    end
end
