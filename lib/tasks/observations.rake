require_relative '../sightings/sightings.rb'

namespace :inaturalist_sightings do
  desc "Update inaturalist sightings"
  task :update, [:from_date, :to_date, :days] => [:environment] do |task, args|
    Rails.logger.info("inaturalist_sightings::update from date: #{args[:from_date]}, to_date: #{args[:to_date]}")
    Sightings.update_inaturalist_sightings(args[:from_date], args[:to_date], args[:days])
  end
end
