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
    search_text = params[:search_by_species]
    contest_id = params[:contest_filter] || params[:contest_id]
    regions_hash = []
    regions = []

    if search_text.present?
      @taxonomy_ids = RegionsObservationsMatview.get_taxonomy_ids(search_text: search_text)
      regions = RegionsObservationsMatview.get_regions_by_species(search_text: search_text, contest_id: contest_id)

      regions.each do |r|
        region_id = r.id
        species_count = RegionsObservationsMatview.get_total_sightings_for_region(region_id: region_id, taxonomy_ids: @taxonomy_ids)
        regions_hash.push({ region: r, total_sightings: species_count, bioscore: r.bioscore })
      end
      sorted_regions = regions_hash.sort_by { |h| [h[:total_sightings], h[:bioscore]] }
                                   .reverse
                                   .map { |row| row[:region] }
      @search_by_species = search_text
      @searched_regions = Kaminari.paginate_array(sorted_regions).page(params[:page]).per(25)
    else
      contest_query = ''
      contest_query = "contests.id = #{contest_id}" if contest_id.present?

      regions = Region.joins(:contests)
                      .where(contest_query)
                      .where('contests.utc_starts_at < ? AND contests.last_submission_accepted_at > ?', Time.now, Time.now)
                      .distinct
                      .order('bioscore desc')
                      .page(params[:page]).per(20)
      @searched_regions = regions
    end

  end

  def sightings_count
    region_id = params[:region_id]
    search_text = params[:search_text] || ''
    species_count = '-'
    taxonomy_ids = params[:taxonomy_ids] || []
    if region_id.present?
      if params[:get_property_sightings] == "true"
        species_count = RegionsObservationsMatview.get_species_count(region_id: region_id, 
                                                                     taxonomy_ids: taxonomy_ids)
      elsif params[:get_locality_sightings] == "true"
        locality = Region.find_by_id(region_id).get_neighboring_region(region_type: 'locality')
        if locality.present?
          species_count = RegionsObservationsMatview.get_species_count(region_id: locality.id,
                                                                       taxonomy_ids: taxonomy_ids)
        end
      elsif params[:get_gr_sightings] == "true"
        greater_region = Region.find_by_id(region_id).get_neighboring_region(region_type: 'greater_region')
        if greater_region.present?
          species_count = RegionsObservationsMatview.get_species_count(region_id: greater_region.id,
                                                                       taxonomy_ids: taxonomy_ids)
        end
      elsif params[:get_total_sightings] == "true"
        species_count = RegionsObservationsMatview.get_total_sightings_for_region(region_id: region_id,
                                                                                  taxonomy_ids: taxonomy_ids)
      end
    end
    species_count_json = { 'species_count': species_count }

    render json: species_count_json
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
