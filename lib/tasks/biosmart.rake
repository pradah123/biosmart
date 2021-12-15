require "biosmart.rb"

namespace :biosmart do
    namespace :sightings do
        desc "Update sightings"
        task :update => :environment do |t, args|
            BioSmart.enqueue_sightings_update()
        end
    end
end
