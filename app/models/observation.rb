class Observation < ApplicationRecord
  scope :recent, -> { order observed_at: :desc }
  scope :has_image, -> { where 'observation_images_count > ?', 0 }
  scope :has_scientific_name, -> { where.not scientific_name: @@filtered_scientific_names }
  scope :from_observation_org, -> { joins(:data_source).where(data_sources: { name: 'observation.org' }) }
  scope :has_creator_id, -> { where.not creator_id: nil }
  scope :without_creator_name, -> { where creator_name: nil }

  has_and_belongs_to_many :regions
  has_and_belongs_to_many :participations
  has_and_belongs_to_many :contests
  belongs_to :data_source
  has_many :observation_images

  after_create :assign_to_contests
  after_update :update_to_contests, if: :saved_change_to_lat || :saved_change_to_lng

  validates :unique_id, presence: true  
  validates :lat, presence: true
  validates :lng, presence: true    
  validates :observed_at, presence: true
 
  def assign_to_contests
    Contest.in_progress.each { |c| c.add_observation self }
  end

  def update_to_contests
    Contest.in_progress.each { |c| c.remove_observation self }
    Contest.in_progress.each { |c| added = c.add_observation self }
  end
    


  @@page_cache = {}
  @@page_cache_last_update = {}
  @@filtered_scientific_names = [nil, 'homo sapiens', 'Homo Sapiens', 'Homo sapiens']
  @@nobservations_per_page = 33

  def self.add_observation_to_page_caches obs, contest, region, participation

=begin
    if top_page_cache.length==0
      @@top_page_cache = 
    end
    if can_add_to_cache(obs)==false
      @@top_page_cache.prepend obs
      @@top_page_cache = @@top_page_cache.shift unless @@top_page_cache.count>@@nobservations_per_page
    end
=end    
  end

  def self.get_observations obj=nil
    key = get_key obj
    now = Time.now
    if @@page_cache[key].blank? || (@@page_cache_last_update[key]>now+5.minutes)
      if obj.nil?
        @@page_cache[key] = Observation.all.has_image.has_scientific_name.recent.first @@nobservations_per_page
      else
        @@page_cache[key] = obj.observations.has_image.has_scientific_name.recent.first @@nobservations_per_page
      end
      @@page_cache_last_update[key] = now
    end
    @@page_cache[key]
  end

  def self.get_key obj
    obj.nil? ? 'top' : "#{ obj.class.name[0] }#{ obj.id }"
  end

  def self.can_add_to_cache obs
    return false if @@filtered_scientific_names.include?(observation.scientific_name)
    return false if obs.observation_images_count==0
    true
  end

  rails_admin do
    list do
      field :id
      field :creator_id          
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at      
    end
    edit do 
      field :creator_id
      field :unique_id
      field :common_name
      field :accepted_name
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at      
    end
    show do
      field :id
      field :creator_id
      field :unique_id
      field :common_name
      field :accepted_name
      field :scientific_name
      field :observed_at
      field :lat
      field :lng
      field :created_at
    end
  end 

end
