class ProgressSummaryController < ApplicationController
  unloadable

  DEFINE_DIGIT_OF_NUMBER = 2

  def index
    @filters_message = ""
    initProgressSummary
    @card_info_list = getCardInfoList("index", @target_project, @version)
    render "show"
  end

  def show
    @filters_message = ""
    initProgressSummary
    find_project
    if @target_project.nil?
      @card_info_list = getCardInfoList("show", @project, @version)
    else
      @card_info_list = getCardInfoList("show", @target_project, @version)
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
      @version = @target_project.versions.find(versionid)
    else
      @version = nil
    end
  end
  
  def getCardInfoList(action, project = nil, version = nil)
    return ProcessCardInfo.getCardInfoList(action, project, version)
  end
end
