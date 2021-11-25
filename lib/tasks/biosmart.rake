require "biosmart.rb"

namespace :biosmart do

    namespace :sightings do

        desc "Update sightings"
        task :update, [:region_id] => :environment do |t, args|
            region_id = args[:region_id]
            if region_id.blank?
                logger.error "Please provide a valid region ID"
                exit
            end
			BioSmart.enqueue_sightings_update(for_region_id: region_id)
        end

    end

end
