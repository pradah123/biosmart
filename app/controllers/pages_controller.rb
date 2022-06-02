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
    @region = Region.find_by_slug params[:slug]
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

    q = cookies[:q].blank? ? '' : cookies[:q].strip.downcase

    if q.length==0
      observations = Observation.get_observations (obj.nil? ? nil : obj.first)
    else  
      if obj.nil?
        observations = Observation.all.has_scientific_name.recent.search q
      else 
        observations = obj.first.observations.has_scientific_name.recent.search q
      end  
    end  
    
    render partial: 'pages/observation_block', locals: { observations: observations[params[:nstart].to_i...params[:nend].to_i] }, layout: false
  end  

end
