class ProgressSummaryController < ApplicationController
  unloadable

  helper ProgressSummaryHelper

  DEFINE_DIGIT_OF_NUMBER = 2
  
  def index
    @filters_message = ""
    initProgressSummary
    @card_info_list = getCardInfoList(@target_project, @target_version, @target_issue)
    render "show"
  end

  def show
    @filters_message = ""
    initProgressSummary
    find_project
    if @target_project.nil?
      @card_info_list = getCardInfoList(@project, nil, @target_issue)
    else
      @card_info_list = getCardInfoList(@target_project, @target_version, @target_issue)
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
    versionid = params[:version_id]
    issueid = params[:parent_issue_id]

    if !projectid.nil?
      @target_project = Project.find(projectid)
    end
    
    if !@target_project.nil? && !versionid.nil?
      @target_version = @target_project.versions.find(versionid)
    else
      @target_version = nil
    end

    if !issueid.nil?
      @target_issue = Issue.find(issueid)
    else
      @target_issue = nil
    end
  end
  
  def getCardInfoList(project = nil, version = nil, issue = nil)
    card_info_list = ProgressCardInfo.getCardInfoList(project, version, issue)
    card_info_list.each do |card_info|
        card_info.percent_progress = card_info.percent_progress.round(DEFINE_DIGIT_OF_NUMBER)
        card_info.days_total_early = card_info.days_total_early.round(DEFINE_DIGIT_OF_NUMBER)
        card_info.days_max_early = card_info.days_max_early.round(DEFINE_DIGIT_OF_NUMBER)
        card_info.days_total_delay = card_info.days_total_delay.round(DEFINE_DIGIT_OF_NUMBER)
        card_info.days_max_delay = card_info.days_max_delay.round(DEFINE_DIGIT_OF_NUMBER)
    end
    return card_info_list
  end
end