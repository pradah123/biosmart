require "biosmart.rb"

namespace :biosmart do
    namespace :sightings do
        desc "Update sightings"
        task :update => :environment do |t, args|
            BioSmart.enqueue_sightings_update()
        end
        desc "Update photo sightings"
        task :update_photos, [:region_id] => :environment do |t, args|
            if args[:region_id].blank?
                Rails.logger.fatal "Please provide region ID."
            end
            BioSmart.enqueue_photo_sightings(for_region_id: args[:region_id])
        end
    end
end
