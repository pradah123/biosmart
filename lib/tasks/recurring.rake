namespace :job do
  namespace :recurring do
    desc 'Schedule ObservationsFetchJob job'
    task schedule: :environment do
      ObservationsFetchJob.perform_later
      FetchObservationOrgUsernameJob.perform_later
    end
  end
end
