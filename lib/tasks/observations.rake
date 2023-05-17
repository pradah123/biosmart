require_relative '../sightings/sightings.rb'

namespace :inaturalist_sightings do
  desc "Update inaturalist sightings"
  task :update, [:from_date, :to_date, :days] => [:environment] do |task, args|
    if `ps aux | pgrep inaturalist_sightings:update` == ""
      Sightings.update_inaturalist_sightings(args[:from_date], args[:to_date], args[:days])
    else
      Rails.logger.info("inaturalist_sightings::update task is already running")
    end
  end
end
