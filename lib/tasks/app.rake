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
