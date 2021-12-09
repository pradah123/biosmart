class Observation < ApplicationRecord
    def format_for_api
        return {
            id: id,
            unique_id: unique_id,
            sname: sname,
            cname: cname,
            obs_dttm: obs_dttm,
            obs_count: obs_count,
            lat: location.y,
            lng: location.x,
            app_id: app_id,
            username: username,
            quality_level: quality_level,
            identifications_count: identifications_count,
            photos_count: photos_count
        }
    end
end
