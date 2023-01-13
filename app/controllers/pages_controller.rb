require './services/region'

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
    @taxonomy_ids = []
    params[:search_text] = search_text = params[:search_by_species] || ''
    contest_id = params[:contest_filter] || params[:contest_id]
    @start_dt = params[:start_dt] || ''
    @end_dt = params[:end_dt] || ''
    regions_hash = []
    regions = []

    if search_text.present?
      @search_by_species = search_text
    end
    search_params = params.to_unsafe_h.symbolize_keys
    Service::Region::SearchBySpecies.call(search_params) do |result|
      result.success do |searched_regions|
        @searched_regions = searched_regions
      end
      result.failure do |message|
        Rails.logger.info(">>>>>>pages_controller::search_species: message: #{message}")
      end
    end
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
