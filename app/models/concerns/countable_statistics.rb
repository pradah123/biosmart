module CountableStatistics
  extend ActiveSupport::Concern
  included do

    def get_nobservations
      self.observations.count
    end  
   
    def get_nspecies
      self.observations.pluck(:accepted_name).uniq.count
    end  
    
    def get_nidentifications
      self.observations.pluck(:identifications_count).sum
    end

    def get_nparticipants
      self.observations.pluck(:creator_name).compact.uniq.count
    end  

  end
end