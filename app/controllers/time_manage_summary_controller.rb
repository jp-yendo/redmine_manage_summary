class TimeManageSummaryController < ApplicationController
  unloadable

  def index
    @filters_message = ""
    initTimeManage
    if !params[:target_date].nil?
      if checkTimeManage == false
        return
      end
      targetuserids = UserInfo.getAllUserIds
      createUserTimeManageData(targetuserids)
    end
    render "show"
  end

  def show
    @filters_message = ""
    initTimeManage
    find_project
    if !params[:target_date].nil?
      if checkTimeManage == false
        return
      end
      targetuserids = UserInfo.getProjectUserIds(@project)
      createUserTimeManageData(targetuserids)
    end
  end

private
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def checkTimeManage
    if params[:show_estimated_hours].nil? && params[:show_entry_hours].nil?
      @filters_message = "" #未選択メッセージ？
      return false
    end
    return true
  end
  
  def initTimeManage
    if params[:target_date].nil?
      @targetdate = Date.today
    else
      @targetdate = params[:target_date].to_date
    end
    if params[:show_estimated_hours].nil?
      @show_estimated_hours = false
    else
      @show_estimated_hours = params[:show_estimated_hours]
    end
    if params[:show_entry_hours].nil?
      @show_entry_hours = false
    else
      @show_entry_hours = params[:show_entry_hours]
    end
    @firstdate = Date::new(@targetdate.year, @targetdate.month, 1)
    @lastdate = Date::new(@targetdate.year, @targetdate.month, -1)
    
    @daycollection = DayInfo.getDayCollection(@firstdate, @lastdate)
  end

  def createUserTimeManageData(targetuserids)
    targetusers = User.where(:id => targetuserids).order("lastname asc")

    @usercollection = []
    userindex = 0
    targetusers.each do |user|
      userinfo = UserInfo::new
      userinfo.info = user

      if @show_estimated_hours == "true"
        userinfo.time_assignments = []

      else
        userinfo.time_assignments = nil
      end

      #実績時間の集計
      if @show_entry_hours == "true"
        userinfo.time_entries = []
        targetindex = 0
        @daycollection.each do |dayinfo|
          timeinfo = TimeInfo::new
          timeinfo.dayinfo = dayinfo
          if @project.nil?
            timeinfo.hour = TimeEntry.where(:user_id => user.id, :spent_on => dayinfo.date).sum(:hours).to_f
          else
            timeinfo.hour = TimeEntry.where(:user_id => user.id, :spent_on => dayinfo.date, :project_id => @project.id).sum(:hours).to_f
          end
          timeinfo.hour = timeinfo.hour.round(3)
          userinfo.time_entries[targetindex] = timeinfo
          targetindex += 1
        end
      else
        userinfo.time_entries = nil
      end
      
      @usercollection[userindex] = userinfo
      userindex += 1
    end
    #Rails.logger.info(targetdate.to_s)
  end
end
