class ObservationsFetchJob < ApplicationJob
  queue_as :queue_observations_fetch

  def perform
    Delayed::Worker.logger.info "\n\n\n\n"
    Delayed::Worker.logger.info ">>>>>>>>>> ObservationsFetchJob fetching observations"
    
    Contest.in_progress.each do |contest|
      contest.participations.in_competition.each do |participant|
        if participant.is_active?
          participant.data_sources.each do |data_source|
            extra_params = contest.get_extra_params(data_source_id: data_source.id) || {}
            data_source.fetch_observations participant.region, contest.starts_at, contest.ends_at, extra_params, participant.id
          end
        end
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>>ObservationsFetchJob completed\n\n\n\n"
  end

end
