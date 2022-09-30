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
      Rails.logger.info ">>> Invalid file #{file_name}"
    end
  end
end
