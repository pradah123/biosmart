class PagesController < ApplicationController

 

  def top
  end

  def region_contest

    @region = Region.find_by_id params[:region_id]
    if @region.nil?
      render :top 
      return
    end
    
    @contest = Contest.find_by_id params[:contest_id]
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
    @region = Region.find_by_id params[:id]
    render :top if @region.nil?
  end

  def contest
    @contest = Contest.find_by_id params[:id]
    render :top if @contest.nil?
  end




  def regions
    if @user.nil?
      render :top 
    else
      @regions = @user.admin? ? Region.all : @user.regions
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
      @participations = @user.admin? ? Participation.all : @user.participations
    end  
  end

  def users
    if @user.nil? || !@user.admin?
      render :top 
    else
      @users = User.all
    end  
  end




  def get_more
    if params[:region_id] && params[:contest_id]
      obj = Participation.where contest_id: params[:contest_id], region_id: params[:region_id]
    elsif params[:region_id]
      obj = Region.where id: params[:region_id]
    elsif params[:contest_id]
      obj = Contest.where id: params[:contest_id]
    else
      obj = nil
    end

    q = cookies[:q].strip.downcase

    if q.length==0
      observations = Observation.get_observations obj.first
    else  
      observations = (obj.nil? ? Observation.all : obj.first.observations).has_image.has_scientific_name.recent.search q
    end  
    
    render partial: 'pages/observation_block', locals: { observations: observations[params[:nstart].to_i...params[:nend].to_i] }, layout: false
  end  

end
