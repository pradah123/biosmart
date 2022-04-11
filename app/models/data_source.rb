class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
  has_many :api_request_logs

  def fetch_observations region
    if name=='observations.org'
      fetch_observations_dot_org region
    else
      self.send "fetch_#{name}", region
    end
  end

  def fetch_observations_dot_org region
    # fetch logic here
    
    []
  end 

  def fetch_inat region
    # fetch logic here
    
    []
  end 

  def fetch_ebird region
    # fetch logic here
    
    []
  end

  def fetch_qgame region
    # fetch logic here
    
    []
  end 
  
end