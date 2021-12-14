require "biosmart.rb"

namespace :biosmart do
    namespace :sightings do
        desc "Update sightings"
        task :update, [:contest_id] => :environment do |t, args|
            contest_id = args[:contest_id]
            if contest_id.blank?
                logger.error "Please provide a valid contest ID"
                exit
            end
			BioSmart.enqueue_sightings_update(for_contest_id: contest_id)
        end
    end
end
