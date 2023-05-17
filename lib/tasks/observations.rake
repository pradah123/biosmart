require_relative '../sightings/sightings.rb'

namespace :inaturalist_sightings do
  desc "Update inaturalist sightings"
  task :update, [:from_date, :to_date, :days] => [:environment] do |task, args|
    Rails.logger.info("inaturalist_sightings::processes running")
    Rails.logger.info(`ps aux | pgrep -f inaturalist_sightings:update`)
    status = `ps aux | pgrep -f inaturalist_sightings:update | tail -n +5`
    Rails.logger.info("inaturalist_sightings::process running? :#{status}")
    if status == ""
      Sightings.update_inaturalist_sightings(args[:from_date], args[:to_date], args[:days])
    else
      Rails.logger.info("inaturalist_sightings::update task is already running")
    end
  end
end
