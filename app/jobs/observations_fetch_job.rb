class ObservationsFetchJob < ApplicationJob
  queue_as :queue_observations_fetch

  def perform 
    Delayed::Worker.logger.info "\n\n\n\n>>>>>>>>>> fetching observations"
    
    Contest.in_progress.each do |contest|
      contest.participations.in_competition.each do |participant|
        if participant.is_active?
          participant.data_sources.each do |data_source|
            data_source.fetch_observations participant.region, get_observation_fetch_begin_time(contest), contest.ends_at
          end
        end
      end
    end

    Delayed::Worker.logger.info ">>>>>>>>>> completed\n\n\n\n"
  end

  def get_observation_fetch_begin_time contest
    if fetch_full_data? contest
      return contest.starts_at
    end

    return contest.starts_at + (Time.now.utc - contest.utc_starts_at)
  end

  def fetch_full_data? contest
    current_time_utc = Time.now.utc
    # Fetch full data every 8 hours or if contest has ended
    return (current_time_utc.utc > contest.utc_ends_at) || ((current_time_utc - contest.utc_starts_at).seconds.in_hours.to_i) % 8 == 0
  end

end
