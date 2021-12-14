class ContestController < ApplicationController
    def counts
        contest = Contest.select(:begin_at, :end_at).find(params[:contest_id])
        if contest.blank?
            raise  BiosmartAPIError.new(
                "Invalid contest: #{contest_id}. Please try again.",
                BiosmartAPIError::EXCEPTION_TYPE
            )
        end
        counts_data = {}
        if params[:observations_count].present?
            counts_data[:observations_count] = Observation.where(
                obs_dttm: contest.begin_at..contest.end_at, 
                deleted_at: nil
            ).count(:id)
        end
        if params[:identifications_count].present?
            counts_data[:identifications_count] = Observation.where(
                obs_dttm: contest.begin_at..contest.end_at, 
                deleted_at: nil
            ).sum(:identifications_count)
        end
        if params[:species_count].present?
            counts_data[:species_count] = Observation.where(
                obs_dttm: contest.begin_at..contest.end_at, 
                deleted_at: nil
            ).where.not(
                clean_sname: nil
            ).distinct.count(:clean_sname)
        end
        if params[:participants_count].present?
            counts_data[:participants_count] = Observation.where(
                obs_dttm: contest.begin_at..contest.end_at, 
                deleted_at: nil
            ).where.not(
                user_id: nil
            ).distinct.count(:user_id)
        end
        render  json: counts_data,
                status: :ok
    end

    def observations
        contest = Contest.select(:begin_at, :end_at).find(params[:contest_id])
        if contest.blank?
            raise  BiosmartAPIError.new(
                "Invalid contest: #{contest_id}. Please try again.",
                BiosmartAPIError::EXCEPTION_TYPE
            )
        end
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
        ).where(obs_dttm: contest.begin_at..contest.end_at)
        if params[:offset].present?
            @observations = @observations.offset(params[:offset])
        end
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
