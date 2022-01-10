class Photo < ApplicationRecord
    belongs_to :observation

    def format_for_api(params={})
        return {
            id: id,
            unique_id: unique_id,
            image_thumb_url: image_thumb_url,
            image_large_url: image_large_url,
            license_code: license_code,
            attribution: attribution,
            license_name: license_name,
            license_url: license_url,
            observation_id: observation_id
        }
    end
end
