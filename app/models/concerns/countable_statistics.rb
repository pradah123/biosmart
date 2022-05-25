module CountableStatistics
  extend ActiveSupport::Concern
  included do

    def add_and_compute_statistics obs
      self.observations << obs
      reset_statistics
    end

    def reset_statistics
      update_column :observations_count, self.observations.count
      update_column :identifications_count, self.observations.pluck(:identifications_count).sum
      update_column :people_count, self.observations.pluck(:creator_name).compact.uniq.count
      update_column :physical_health_score, get_physical_health_score
      update_column :mental_health_score, get_mental_health_score

      #update_column :species_count, self.observations.pluck(:accepted_name).uniq.count
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

  end
end
