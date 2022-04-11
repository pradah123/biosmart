class ObservationsFetchJob < ApplicationJob
  queue_as :default

  def perform 
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> fetching observations"
    
    Contest.in_progress.each do |contest|
      contest.participations.in_competition do |participant|
        participant.data_sources.each do |data_source|
          observations = data_source.fetch_observations participant.region
          ObservationsCreateJob.perform_later data_source, observations
        end
      end
    end      

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end
end
