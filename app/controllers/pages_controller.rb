class PagesController < ApplicationController

  def top
  end

  def region_contest

    @region = Region.find_by_slug params[:region_slug]
    if @region.nil?
      render :top 
      return
    end
    
    @contest = Contest.find_by_slug params[:contest_slug]
    if @contest.nil?
      render :top
      return
    end  

    @participation = Participation.where region_id: @region.id, contest_id: @contest.id
    if @participation.empty?
      render :top 
      return
    end  
    
    @participation = @participation.first
  end

  def region
    @region = Region.all.online.find_by_slug params[:slug]
    render :top if @region.nil?
  end

  def contest
    @contest = Contest.find_by_slug params[:slug]
    render :top if @contest.nil?
  end

  def regions
    if @user.nil?
      render :top 
    else
      @regions = @user.admin? ?
                 Region.where(base_region_id: nil).order(created_at: :desc).page(params[:page]) :
                 @user.regions.where(base_region_id: nil).order(created_at: :desc).page(params[:page])
    end
  end

  def contests
    if @user.nil?
      render :top
    else
      @contests = @user.admin? ? Contest.all : @user.contests
      @contests_through_regions = @user.regions.map { |r| r.contests }.flatten.uniq
    end
  end

  def participations
    if @user.nil?
      render :top 
    else
      @participations = @user.admin? ? Participation.base_region_participations : @user.participations.base_region_participations
    end  
  end

  def users
    if @user.nil? || !@user.admin?
      render :top 
    else
      @users = User.all
    end  
  end


  def region_bioscore
    @region = Region.all.online.find_by_slug params[:slug]
    render :top if @region.nil?
    render layout: "basic_template"
  end

  def search_species
    @searched_regions = []
    search_text = params[:search_by_species]
    if search_text.present?
      region_ids = []
      region_ids = Region.joins(:observations)
                         .where("lower(observations.scientific_name) like ? or lower(observations.common_name) like ?", "%#{search_text.downcase}%", "%#{search_text.downcase}%")
                         .where(base_region_id: nil)
                         .distinct
                         .pluck(:region_id)
      region_ids += Region.joins(:observations)
                          .where("lower(observations.scientific_name) like ? or lower(observations.common_name) like ?", "%#{search_text.downcase}%", "%#{search_text.downcase}%")
                          .where.not(base_region_id: nil)
                          .distinct
                          .pluck(:base_region_id)
      @searched_regions = Region.where(id: region_ids)                      
      @search_by_species = params[:search_by_species]
    end
  end

  def sightings_count
    region_id = params[:region_id]
    search_text = params[:search_text]
    species_count = '-'
    if region_id.present? && search_text.present?
      if params[:get_property_sightings] == "true"
        species_count = RegionsObservationsMatview.get_species_count(region_id: region_id, search_text: search_text)
      elsif params[:get_locality_sightings] == "true"
        locality = Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
        species_count = RegionsObservationsMatview.get_species_count(region_id: locality.id, search_text: search_text) if locality.present?
      elsif params[:get_gr_sightings] == "true"
        greater_region = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
        species_count = RegionsObservationsMatview.get_species_count(region_id: greater_region.id, search_text: search_text) if greater_region.present?
      elsif params[:get_total_sightings] == "true"
        locality_species_count = greater_region_species_count = 0
        species_count = RegionsObservationsMatview.get_species_count(region_id: region_id, search_text: search_text)
        locality = Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
        locality_species_count = RegionsObservationsMatview.get_species_count(region_id: locality.id, search_text: search_text) if locality.present?
        greater_region = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
        greater_region_species_count = RegionsObservationsMatview.get_species_count(region_id: greater_region.id, search_text: search_text) if greater_region.present?
        species_count = species_count + locality_species_count + greater_region_species_count
      end
    end

    species_count_json = { 'species_count': species_count }

    render :json => species_count_json

  end

  def get_more
    result = Observation.get_search_results params[:region_id], params[:contest_id], cookies[:q],
                                            params[:nstart].to_i, params[:nend].to_i, cookies[:category]
    render partial: 'pages/observation_block', locals: { 
      observations: result[:observations],
      nobservations: result[:nobservations],
      nobservations_excluded: result[:nobservations_excluded]
    }, layout: false
  end



end
