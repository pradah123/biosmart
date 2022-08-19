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
      update_column :observations_count, self.observations.count
      update_column :identifications_count, self.observations.pluck(:identifications_count).sum
      update_column :people_count, self.observations.pluck(:creator_name).compact.uniq.count
      update_column :physical_health_score, get_physical_health_score
      update_column :mental_health_score, get_mental_health_score

      #
      # update_column :species_count, self.observations.pluck(:accepted_name).uniq.count
      # 
      # the above count is not used because the species names are not normalized across
      # data sources. thus the same species will have multiple names, and counts of unique values
      # is not possible
      #
      update_column :species_count, self.observations.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
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
      total_hours = Constant.find_by_name('average_hours_per_observation').value * self.observations.count
      ( (total_hours<5 ? constant_a : constant_b) * constant * self.people_count ).round
    end

    # Compute observations count for given object, optionally for given date range
    def get_observations_count(start_dt: nil, end_dt: nil)
      if start_dt.present? && end_dt.present?
        return self.observations.where("observed_at BETWEEN ? and ?", start_dt ,end_dt).count
      else
        return self.observations.count
      end
    end

    # Compute species count for given object, optionally for given date range
    def get_species_count(start_dt: nil, end_dt: nil)
      if start_dt.present? && end_dt.present?
        return self.observations.where("observed_at BETWEEN ? and ?", start_dt ,end_dt).has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
      else
        return self.observations.has_accepted_name.ignore_species_code.select(:accepted_name).distinct.count
      end
    end

    # Compute people count for given object, optionally for given date range
    def get_people_count(start_dt: nil, end_dt: nil)
      if start_dt.present? && end_dt.present?
        return self.observations.where("observed_at BETWEEN ? and ?", start_dt ,end_dt).select(:creator_name).compact.uniq.count
      else
        return self.observations.select(:creator_name).compact.uniq.count
      end
    end

    #
    # these functions compute the rankings of people and species
    # used on the regions and contest page.
    #

    def get_top_species n=nil
      get_ranking self.observations.pluck(:scientific_name), n
    end  

    def get_top_people n=nil
      get_ranking self.observations.pluck(:creator_name), n
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
      if nr.present?
        start_dt = nr.observations.order("observed_at").first.observed_at if nr.observations.order("observed_at").first.present? 
        end_dt = nr.observations.order("observed_at").last.observed_at if nr.observations.order("observed_at").last.present? 
      else
        start_dt = observations.order("observed_at").first.observed_at if observations.order("observed_at").first.present?
        end_dt = observations.order("observed_at").last.observed_at if observations.order("observed_at").last.present?
      end

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
            nr_obs_count = nr.get_observations_count(start_dt: report_start_dt, end_dt: report_end_dt)
            base_region_obs_count = get_observations_count(start_dt: report_start_dt, end_dt: report_end_dt)
            return nr_obs_count.present? && nr_obs_count != 0 ? sprintf('%.2f', base_region_obs_count * 100/nr_obs_count.to_f) : sprintf('%.2f', 0)
          when 'species_score'
            nr_species_count = nr.get_species_count(start_dt: report_start_dt, end_dt: report_end_dt)
            base_region_species_count = get_species_count(start_dt: report_start_dt, end_dt: report_end_dt)
            return nr_species_count.present? && nr_species_count != 0 ? sprintf('%.2f', base_region_species_count * 100/nr_species_count.to_f) : sprintf('%.2f', 0)
          when 'people_score'
            nr_people_count = nr.get_species_count(start_dt: report_start_dt, end_dt: report_end_dt)
            base_region_people_count = get_species_count(start_dt: report_start_dt, end_dt: report_end_dt)
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
        yearly_count = get_observations_count(start_dt: start_dt, end_dt: end_dt)
        total_count = get_observations_count(start_dt: report_start_dt, end_dt: report_end_dt)
      when 'species_score'
        yearly_count = get_species_count(start_dt: start_dt, end_dt: end_dt)
        total_count = get_species_count(start_dt: report_start_dt, end_dt: report_end_dt)
      when 'people_score'
        yearly_count = get_people_count(start_dt: start_dt, end_dt: end_dt)
        total_count = get_people_count(start_dt: report_start_dt, end_dt: report_end_dt)
      end
      return total_count != 0 ? sprintf('%.2f', yearly_count * 100 /total_count.to_f) : sprintf('%.2f', 0)
    end
  end
end


