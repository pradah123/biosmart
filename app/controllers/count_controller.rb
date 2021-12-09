class CountController < ApplicationController
    def observations_count
        obs_count = Observation.count(:id)
        render  json: {count: obs_count}, 
                status: :ok
    end

    def identifications_count
        id_count = Observation.where.not(identifications_count: nil).sum(:identifications_count)
        render  json: {count: id_count}, 
                status: :ok
    end

    def species_count
        species_count = Observation.where.not(sname: nil).distinct.count(:sname)
        render  json: {count: species_count}, 
                status: :ok
    end

    def participants_count
        participants_count = Observation.where.not(user_id: nil).distinct.count(:user_id)
        render  json: {count: participants_count}, 
                status: :ok
    end
end
