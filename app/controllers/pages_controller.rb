class PagesController < ApplicationController

  def top
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

  def region
    @region = Region.find_by_id params[:id]
    render :top if @region.nil?
  end

  def contest
    @contest = Contest.find_by_id params[:id]
    render :top if @contest.nil?
  end

end
