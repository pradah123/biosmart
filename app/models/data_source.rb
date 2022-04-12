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
        self.send "fetch_#{name}", region
      end
    end
  end

  def fetch_observations_dot_org subregion, starts_at, ends_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:date_after] = starts_at.strftime('%F')
    params[:date_before] = ends_at.strftime('%F')
    loop do
      ob_org = ::Source::ObservationOrg.new(id, **params)
      observations = ob_org.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if ob_org.done()
      params[:offset] = ob_org.next_offset()
    end 
  end 

  def fetch_inat subregion, starts_at, ends_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:d1] = starts_at.strftime('%F')
    params[:d2] = ends_at.strftime('%F')
    inat = ::Source::Inaturalist.new(id, **params)
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
    data_source_id = subregion.data_source_id
    params = subregion.get_params_dict()
    params[:back] = (Time.now - starts_at).to_i / (24 * 60 * 60)
    loop do
      ebird = ::Source::Ebird.new(id, **params)
      observations = qgame.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if qgame.done()
      params[:offset] = qgame.next_offset()
    end
  end

  def fetch_qgame subregion, starts_at, ends_at
    # fetch logic here
    params = subregion.get_params_dict()
    params[:start_dttm] = starts_at.strftime('%F')
    params[:end_dttm] = ends_at.strftime('%F')
    loop do
      qgame = ::Source::QGame.new(id, **params)
      observations = qgame.get_observations()
      ObservationsCreateJob.perform_later self, observations
      break if qgame.done()
      params[:offset] = qgame.next_offset()
    end
  end 
  
end
