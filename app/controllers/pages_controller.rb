class PagesController < ApplicationController

  def top
  end

  def regions
    render :top if @user.nil?
    @regions = @user.regions
  end

  def contests
    render :top if @user.nil?
    @contests = @user.contests
    @contests_through_regions = @user.regions.map { |r| r.contests }.flatten.uniq
  end

  def users
    render :top if @user.nil? || !@user.admin?
    @users = User.all
  end
  
    


  def region
    @region = Region.find_by_id params[:id]
    render :top if @region.nil?
  end

  def contest
    @contest = Contest.find_by_id params[:id]
    render :top if @contest.nil?
  end



  def profile
  end  

end
