require_relative '../../../lib/common/utils.rb'

module CountableStatistics
  extend ActiveSupport::Concern
  included do

    #
    # this code deals with updating the counts of observations and other related information. 
    # since we want this information for regions, contests, and participants in a contest, the
    # code is here in a concern, so that the code can be used in those three models.
    #

    def add_and_compute_statistics obs
      self.observations << obs
      reset_statistics
    end

    # def add_observation region, obs
    #   region.observations << obs
    #   add_observation region.parent_region, obs unless region.parent_region_id.nil?
    # end

    def reset_statistics
      if self.is_a? Region
        update_column :observations_count, self.get_observations_count(include_gbif: true)
        update_column :people_count, self.get_people_count(include_gbif: true)
        update_column :species_count, self.get_species_count(include_gbif: true)
        update_column :identifications_count, self.get_identifications_count(include_gbif: true)
        update_column :bioscore, self.get_bio_score(include_gbif: true)
      else 
        update_column :observations_count, self.observations.count
        update_column :identifications_count, self.observations.pluck(:identifications_count).sum
        update_column :people_count, self.observations.pluck(:creator_name).compact.uniq.count
        update_column :species_count, self.observations.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
      end
      update_column :physical_health_score, get_physical_health_score
      update_column :mental_health_score, get_mental_health_score
      #
      # update_column :species_count, self.observations.pluck(:accepted_name).uniq.count
      # 
      # the above count is not used because the species names are not normalized across
      # data sources. thus the same species will have multiple names, and counts of unique values
      # is not possible
      #
    end

    def get_physical_health_score
      get_score Constant.find_by_name('physical_health_score_constant').value,
        Constant.find_by_name('physical_health_score_constant_a').value,
        Constant.find_by_name('physical_health_score_constant_b').value
    end

    def get_mental_health_score
      get_score Constant.find_by_name('mental_health_score_constant').value,
        Constant.find_by_name('mental_health_score_constant_a').value,
        Constant.find_by_name('mental_health_score_constant_b').value
    end

    def get_score constant, constant_a, constant_b
      if self.is_a? Region 
        observations = Observation.get_observations_for_region(region_id: self.id, include_gbif: true)
        people_count = get_people_count(include_gbif: true)
      else 
        observations = self.observations
        people_count = self.people_count
      end 
      total_hours = Constant.find_by_name('average_hours_per_observation').value * observations.count
      ( (total_hours < 5 ? constant_a : constant_b) * constant * people_count ).round
    end

    # Compute observations count for given region, optionally for given date range
    def get_observations_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = Observation.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt, include_gbif: include_gbif)
      else
        obs = Observation.get_observations_for_region(region_id: self.id, include_gbif: include_gbif)
      end

      return obs.count
    end

    # Compute species count for given region, optionally for given date range
    def get_species_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = Observation.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt, include_gbif: include_gbif)
      else
        obs = Observation.get_observations_for_region(region_id: self.id, include_gbif: include_gbif)
      end

      return obs.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
    end

    # Compute people count for given region, optionally for given date range
    def get_people_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = Observation.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt, include_gbif: include_gbif)
      else
        obs = Observation.get_observations_for_region(region_id: self.id, include_gbif: include_gbif)
      end

      return obs.select(:creator_name).where.not(creator_name: nil).distinct.count
    end

    # Compute identifications count for given region, optionally for given date range
    def get_identifications_count(start_dt: nil, end_dt: nil, include_gbif: false)
      if start_dt.present? && end_dt.present?
        obs = Observation.get_observations_for_region(region_id: self.id, start_dt: start_dt, end_dt: end_dt, include_gbif: include_gbif)
      else
        obs = Observation.get_observations_for_region(region_id: self.id, include_gbif: include_gbif)
      end

      return obs.sum(:identifications_count)
    end

    #
    # these functions compute the rankings of people and species
    # used on the regions and contest page.
    #

    def get_top_species n=nil
      if self.is_a? Region
        obs = Observation.get_observations_for_region(region_id: self.id, include_gbif: true)
        get_ranking obs.pluck(:scientific_name), n
      else 
        get_ranking self.observations.pluck(:scientific_name), n
      end
    end  

    def get_top_people n=nil
      if self.is_a? Region
        obs = Observation.get_observations_for_region(region_id: self.id, include_gbif: true)
        get_ranking obs.pluck(:creator_name), n
      else 
        get_ranking self.observations.pluck(:creator_name), n
      end
    end  

    def get_ranking arr, n
      #
      # rank by count, in descending order
      # when n is nil take all values, otherwise take the top n
      #
      arr.tally.sort_by { |k,v| -v }.first (n.nil? || n<1 ? arr.length : n)
    end

    # Calculate start date and end date which will be used to fetch different report scores
    def get_date_range_for_report(format: false)
      nr = get_neighboring_region(region_type: 'greater_region')
      end_dt = Time.now.utc
      start_dt = end_dt - Utils.convert_to_seconds(unit:'year', value: 3)

      region_id = nr.present? ? nr.id : self.id
      obs = Observation.get_observations_for_region(region_id: region_id, include_gbif: true)
      start_dt =  obs&.order("observed_at")&.first&.observed_at || start_dt
      end_dt   =  obs&.order("observed_at")&.last&.observed_at || end_dt

      return format == true ? [start_dt.strftime("%Y-%m-%d"), end_dt.strftime("%Y-%m-%d")] : [start_dt, end_dt]

    end


    # Compute regions scores by comparing the counts with that of neighboring regions
    def get_regions_score(region_type: nil, score_type: , num_years: nil)
      if region_type.present?
        nr = get_neighboring_region(region_type: region_type)

        if nr.present?
          (report_start_dt, report_end_dt) = get_date_range_for_report()
          case score_type
          when 'observations_score'
            nr_obs_count = nr.get_observations_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
            base_region_obs_count = get_observations_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
            return nr_obs_count.present? && nr_obs_count != 0 ? sprintf('%.2f', base_region_obs_count * 100/nr_obs_count.to_f) : sprintf('%.2f', 0)
          when 'species_score'
            nr_species_count = nr.get_species_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
            base_region_species_count = get_species_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
            return nr_species_count.present? && nr_species_count != 0 ? sprintf('%.2f', base_region_species_count * 100/nr_species_count.to_f) : sprintf('%.2f', 0)
          when 'people_score'
            nr_people_count = nr.get_people_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
            base_region_people_count = get_people_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
            return nr_people_count.present? && nr_people_count != 0 ? sprintf('%.2f', base_region_people_count * 100/nr_people_count.to_f) : sprintf('%.2f', 0)
          end
        end
      end
    end


    # Compute yearly scores by comparing yearly counts for given no. of years vs total count
    def get_yearly_score(score_type: , num_years:)
      (report_start_dt, report_end_dt) = get_date_range_for_report()

      end_dt = report_end_dt
      start_dt = end_dt - Utils.convert_to_seconds(unit:'year', value: num_years)

      total_count = yearly_count = 0
      case score_type
      when 'observations_score'
        yearly_count = get_observations_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
        total_count = get_observations_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
      when 'species_score'
        yearly_count = get_species_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
        total_count = get_species_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
      when 'people_score'
        yearly_count = get_people_count(start_dt: start_dt, end_dt: end_dt, include_gbif: true)
        total_count = get_people_count(start_dt: report_start_dt, end_dt: report_end_dt, include_gbif: true)
      end
      return total_count != 0 ? sprintf('%.2f', yearly_count * 100 /total_count.to_f) : sprintf('%.2f', 0)
    end
  end

  def get_total_vs_neighboring_regions_bio_score
    total_vs_locality_obs_score            = get_regions_score(region_type: 'locality', score_type: 'observations_score').to_f / 100
    total_vs_locality_species_score        = get_regions_score(region_type: 'locality', score_type: 'species_score').to_f / 100
    total_vs_locality_activity_score       = get_regions_score(region_type: 'locality', score_type: 'people_score').to_f / 100
    total_vs_greater_region_obs_score      = get_regions_score(region_type: 'greater_region', score_type: 'observations_score').to_f / 100
    total_vs_greater_region_species_score  = get_regions_score(region_type: 'greater_region', score_type: 'species_score').to_f / 100
    total_vs_greater_region_activity_score = get_regions_score(region_type: 'greater_region', score_type: 'people_score').to_f / 100

    locality_obs_constant     = Constant.find_by_name('locality_observations_constant')&.value || 1
    locality_species_constant = Constant.find_by_name('locality_species_constant')&.value || 1
    locality_people_constant  = Constant.find_by_name('locality_people_constant')&.value || 1

    gr_obs_constant     = Constant.find_by_name('greater_region_observations_constant')&.value || 1
    gr_species_constant = Constant.find_by_name('greater_region_species_constant')&.value || 1
    gr_people_constant  = Constant.find_by_name('greater_region_people_constant')&.value || 1

    total_vs_neighboring_regions_score = (total_vs_locality_obs_score * locality_obs_constant) + (total_vs_locality_species_score * locality_species_constant) +
                                         (total_vs_locality_activity_score * locality_people_constant) + (total_vs_greater_region_obs_score * gr_obs_constant) +
                                         (total_vs_greater_region_species_score * gr_species_constant) + (total_vs_greater_region_activity_score * gr_people_constant)
    return total_vs_neighboring_regions_score
  end


  def get_yearly_bio_score
    yearly_vs_total_obs_score         = get_yearly_score(score_type: 'observations_score', num_years: 1).to_f / 100
    yearly_vs_total_species_score     = get_yearly_score(score_type: 'species_score', num_years: 1).to_f / 100
    yearly_vs_total_activity_score    = get_yearly_score(score_type: 'people_score', num_years: 1).to_f / 100
    bi_yearly_vs_total_obs_score      = get_yearly_score(score_type: 'observations_score', num_years: 2).to_f / 100
    bi_yearly_vs_total_species_score  = get_yearly_score(score_type: 'species_score', num_years: 2).to_f / 100
    bi_yearly_vs_total_activity_score = get_yearly_score(score_type: 'people_score', num_years: 2).to_f / 100

    curr_year_obs_constant     = Constant.find_by_name('current_year_observations_constant')&.value || 1
    curr_year_species_constant = Constant.find_by_name('current_year_species_constant')&.value || 1
    curr_year_people_constant  = Constant.find_by_name('current_year_people_constant')&.value || 1

    obs_trend      = (bi_yearly_vs_total_obs_score.positive? ? (yearly_vs_total_obs_score - (bi_yearly_vs_total_obs_score/2))/ (bi_yearly_vs_total_obs_score/2) : 0)
    species_trend  = (bi_yearly_vs_total_species_score.positive? ? (yearly_vs_total_species_score - (bi_yearly_vs_total_species_score/2))/ (bi_yearly_vs_total_species_score/2) : 0)
    activity_trend = (bi_yearly_vs_total_activity_score.positive? ? (yearly_vs_total_activity_score - (bi_yearly_vs_total_activity_score/2))/ (bi_yearly_vs_total_activity_score/2) : 0)

    obs_trend_constant      = Constant.find_by_name('observations_trend_constant')&.value || 1
    species_trend_constant  = Constant.find_by_name('species_trend_constant')&.value || 1
    activity_trend_constant = Constant.find_by_name('activity_trend_constant')&.value || 1

    yearly_bio_score = (yearly_vs_total_obs_score * curr_year_obs_constant)          + (yearly_vs_total_species_score * curr_year_species_constant) +
                       (yearly_vs_total_activity_score * curr_year_people_constant)  + (bi_yearly_vs_total_obs_score * obs_trend_constant) +
                       (bi_yearly_vs_total_species_score * species_trend_constant)   + (bi_yearly_vs_total_activity_score * activity_trend_constant) +
                       (obs_trend * obs_trend_constant)  + (species_trend * species_trend_constant) +
                       (activity_trend * activity_trend_constant)

    return yearly_bio_score
  end


  # Calculate bioscore for region using
  # a. region's total vs neighnoring regions observations, species and activity scores
  # b. region's total vs yearly and bi yearly observations, species and activity scores and trends
  # c. region's observations per species and observations per person counts
  def get_bio_score(include_gbif: false)
    obs_count = get_observations_count(include_gbif: include_gbif)
    species_count = get_species_count(include_gbif: include_gbif)
    people_count = get_people_count(include_gbif: include_gbif)

    if obs_count.positive?
      observations_per_species = species_count.positive? ? obs_count / species_count : 0
      observations_per_person  = people_count.positive? ? obs_count / people_count : 0
      avg_obs_score = Constant.find_by_name('average_observations_score')&.value || 20

      active_proportion_constant = Constant.find_by_name('active_proportion_constant')&.value || 1
      obs_per_species_constant = Constant.find_by_name('observations_per_species_constant')&.value || 1
      obs_per_person_constant = Constant.find_by_name('observations_per_person_constant')&.value || 1
      avg_obs_score_constant = Constant.find_by_name('average_observations_score_constant')&.value || 1
      activity_proportion_score = (population.present? ? ((people_count/self.population) * active_proportion_constant ) : 0 )

      observations = Observation.get_observations_for_region(region_id: self.id, include_gbif: true)
      bio_value = observations.average(:bioscore)
      bio_value = bio_value.zero? ? avg_obs_score : bio_value

      bioscore = get_total_vs_neighboring_regions_bio_score()          + get_yearly_bio_score() +
                 (observations_per_species * obs_per_species_constant) + (observations_per_person * obs_per_person_constant) +
                 (bio_value * avg_obs_score_constant) + activity_proportion_score

      return sprintf('%.2f', bioscore).to_f
    else
      return 0
    end
  end
end


