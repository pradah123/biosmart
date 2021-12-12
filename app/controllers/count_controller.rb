class CountController < ApplicationController
    def observations_count
        obs_count = Observation.where(deleted_at: nil).count(:id)
        render  json: {count: obs_count}, 
                status: :ok
    end

    def identifications_count
        id_count = Observation.where(deleted_at: nil).sum(:identifications_count)
        render  json: {count: id_count}, 
                status: :ok
    end

    def species_count
        species_count = Observation.where(
            'clean_sname IS NOT NULL AND deleted_at IS NULL'
        ).distinct.count(:clean_sname)
        render  json: {count: species_count}, 
                status: :ok
    end

    def participants_count
        participants_count = Observation.where(
            'user_id IS NOT NULL AND deleted_at IS NULL'
        ).distinct.count(:user_id)
        render  json: {count: participants_count}, 
                status: :ok
    end
end
