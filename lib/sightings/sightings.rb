require_relative '../source/inaturalist.rb'

module Sightings
  def self.file_name
    return "#{Rails.root}/lib/sightings/.to_date.txt"
  end

  def self.update_inaturalist_sightings(from_date, to_date, days)
    # file_name = "#{Rails.root}/lib/sightings/.to_date.txt"
    file = File.open(self.file_name, "r") if File.file?(self.file_name)
    file_to_date = file.read if file.present?
    file.close()
    unless from_date.present?
      to_date = file_to_date.present? ? file_to_date.to_time : Time.now.utc
      from_date = to_date - Utils.convert_to_seconds(unit: 'days', value: days.to_i)
    end
    data_source_id = DataSource.find_by_name("inaturalist")
    
    unique_ids = Observation.where("observed_at BETWEEN ? and ?", from_date, to_date)
                            .where(data_source_id: data_source_id)
                            .ignore_reserved_sightings
                            .order("observed_at desc")
                            .pluck(:unique_id)
    Rails.logger.info("Sightings::filter_inaturalist_sightings no. of observations to be fetched from #{from_date} - to #{to_date}: #{unique_ids.count}")

    unique_ids.each do |unique_id|
      id = unique_id.gsub('inaturalist-', '')
      Rails.logger.info("Fetching observation for id: #{id}")
      attributes = fetch_sighting_from_inaturalist(from_date, to_date, id)
      next unless attributes.present?

      obs = Observation.find_by_unique_id unique_id
      obs.attributes = attributes
      
      begin
        obs.save unless obs.changed.empty?
        observed_at = obs.observed_at.to_s
        file = File.open(file_name, "w") if File.file?(file_name)
        file.write(observed_at)
        file.close()
      rescue => e
        Rails.logger.info("Failed to update inaturalist license code for sighting #{unique_id}, #{e}")
      end

      sleep(1)
    end
  end

  def self.fetch_sighting_from_inaturalist(from_date, to_date, id)
    params = { 
      d1: from_date.strftime('%Y-%m-%d'),
      d2: to_date.strftime('%Y-%m-%d'),
      lat: -36.90512555988591, # Any lat, just to satisfy ::Source::Inaturalist structure
      lng: 174.5181026210274, # Any lng, just to satisfy ::Source::Inaturalist structure
      radius: 59, # Any radius, just to satisfy ::Source::Inaturalist structure
      id: id
    }
    inaturalist = ::Source::Inaturalist.new(**params)
    attributes = inaturalist.get_observations()
    attributes = attributes[0]
    attributes.delete :image_urls if attributes.present?
    return attributes
  end
end

