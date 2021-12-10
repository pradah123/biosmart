class ObservationsController < ApplicationController
    def index
        # Observation.includes(:photos).where(, 'photos.deleted_at': nil).order('obs_dttm desc').limit(10)
        @observations = Observation.where('observations.deleted_at': nil).order('obs_dttm desc').select(
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
        )
        if params[:limit].present?
            @observations = @observations.limit(params[:limit])
        end
        if params[:include_photos].present?
            @observations = @observations.includes(:photos).where(
                'photos.deleted_at': nil
            ).where('photos_count > 0')
        end
        observations_data = @observations.map{ |o| 
            o.format_for_api(include_photos: params[:include_photos])
        }
        render  json: observations_data, 
                status: :ok
    end
end
