require_relative '../../lib/source/inaturalist.rb'
require_relative '../../lib/source/ebird.rb'
require_relative '../../lib/source/qgame.rb'
require_relative '../../lib/source/observation_org.rb'

class DataSource < ApplicationRecord
  has_and_belongs_to_many :participations
  has_many :observations
  has_many :api_request_logs

  def fetch_observations region, starts_at, ends_at
    subregions = Subregion.where(region_id: region.id, data_source_id: id)
    subregions.each do |sr|
      case name
      when 'inaturalist'
        fetch_inat sr, starts_at, ends_at
      when 'ebird'
        fetch_ebird sr, starts_at, ends_at
      when 'qgame'
        fetch_qgame sr, starts_at, ends_at
      when 'observation.org'
        fetch_observations_dot_org sr, starts_at, ends_at
      else
        self.send "fetch_#{name}", region # PRW: if you have the explicit case statements, we don't need this
      end
    end
  end

  def fetch_observations_dot_org subregion, starts_at, ends_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:date_after] = starts_at.strftime('%F')
    params[:date_before] = ends_at.strftime('%F')
    loop do
      ob_org = ::Source::ObservationOrg.new(**params)
      observations = ob_org.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if ob_org.done()
      params[:offset] = ob_org.next_offset()
    end 
  end 

  def fetch_inat subregion, starts_at, ends_at # PRW: we should change this to fetch_inaturalist to be consistent
    # fetch logic here
    params = subregion.get_params_dict()
    params[:d1] = starts_at.strftime('%F')
    params[:d2] = ends_at.strftime('%F')
    inat = ::Source::Inaturalist.new(**params)
    loop do
      break if inat.done()
      observations = inat.get_observations()
      Rails.logger.info observations
      ObservationsCreateJob.perform_later self, observations
      inat.increment_page()
    end
  end 

  def fetch_ebird subregion, starts_at, ends_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:back] = (Time.now - starts_at).to_i / (24 * 60 * 60)
    ebird = ::Source::Ebird.new(**params)
    observations = ebird.get_observations()
    ObservationsCreateJob.perform_later self, observations    
  end

  def fetch_qgame subregion, starts_at, ends_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:start_dttm] = starts_at.strftime('%F')
    params[:end_dttm] = ends_at.strftime('%F')
    qgame = ::Source::QGame.new(**params)
    loop do
      break if qgame.done()
      observations = qgame.get_observations()
      ObservationsCreateJob.perform_later self, observations
      qgame.increment_offset()
    end
  end 
  
end
