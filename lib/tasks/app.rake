require_relative '../taxonomy/taxonomy_file_process.rb'
require_relative '../common/utils.rb'

namespace :jobs do
  desc 'Schedule ObservationsFetchJob job'
  task schedule: :environment do
    ObservationsFetchJob.perform_later
    FetchObservationOrgUsernameJob.perform_later
  end  
end

namespace :statistics do
  desc 'Schedule Reset Statistics'
  task reset: :environment do
    ## Reset statistics
    Region.all.each        { |r| r.reset_statistics }
    Participation.all.each { |p| p.reset_statistics }
    Contest.all.each       { |c| c.reset_statistics }
  end
end

namespace :taxonomy do
  desc 'Store Taxonomy'
  task :store, [:file_name, :read_from_last_processed] => [:environment] do |task, args|
    if Utils.valid_file?(file_name: args[:file_name])
      TaxonomyFileProcess.process_file(file_name: args[:file_name],
                                       read_from_last_processed: args[:read_from_last_processed])
    else
      Rails.logger.info ">>> taxonomy:store::Invalid file #{args[:file_name]}"
    end
  end

  desc 'Update Taxonomy to Observations'
  task :update, [:update_all] => [:environment] do |task, args|
    Observation.update_observations_taxonomy(update_all: args[:update_all])
  end
end

namespace :participation_species_matview do
  desc 'Update participation_species_matview'
  task refresh: :environment do
    ParticipationSpeciesMatview.refresh
  end
end

namespace :participation_observer_species_matview do
  desc 'Update participation_observer_species_matview'
  task refresh: :environment do
    ParticipationObserverSpeciesMatview.refresh
  end
end
