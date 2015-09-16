class ProgressSummaryController < ApplicationController
  unloadable

  DEFINE_DIGIT_OF_NUMBER = 2
  
  def index
    @filters_message = ""
    initProgressSummary
    @card_info_list = getCardInfoList("index", @target_project, @target_version)
    render "show"
  end

  def show
    @filters_message = ""
    initProgressSummary
    find_project
    if @target_project.nil?
      @card_info_list = getCardInfoList("show", @project, nil)
    else
      @card_info_list = getCardInfoList("show", @target_project, @target_version)
    end
  end

private
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def initProgressSummary
    projectid = params[:project_id]
    versionid = params[:version]

    if !projectid.nil?
      @target_project = Project.find(projectid)
    end
    
    if !@target_project.nil? && !versionid.nil?
      @target_version = @target_project.versions.find(versionid)
    else
      @target_version = nil
    end
  end
  
  def getCardInfoList(action, project = nil, version = nil)
    @action = action
    card_info_list = ProgressCardInfo.getCardInfoList(project, version)
    card_info_list.each do |card_info|
        card_info.percent_progress = card_info.percent_progress.round(DEFINE_DIGIT_OF_NUMBER)
        card_info.days_early = card_info.days_early.round(DEFINE_DIGIT_OF_NUMBER)
        card_info.days_delay = card_info.days_delay.round(DEFINE_DIGIT_OF_NUMBER)
    end
    return card_info_list
  end
end