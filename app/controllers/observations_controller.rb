class ObservationsController < ApplicationController
    def index
        @observations = Observation.where.not(deleted_at: nil).select(
            :id,
            :unique_id,
            :sname,
            :cname,
            :obs_dttm,
            :obs_count,
            :location,
            :app_id,
            :username,
            :quality_level,
            :identifications_count,
            :photos_count
        ).map{|o| o.format_for_api()}
        render  json: @observations, 
                status: :ok
    end
end
