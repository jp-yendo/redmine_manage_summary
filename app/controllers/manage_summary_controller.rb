class ManageSummaryController < ApplicationController
  unloadable

  def index
    initcontroller
    if !params[:target_date].nil?
      targetuserids = UserManager::getAllUserIds
      createUserEntryData(targetuserids)
    end
    render "show"
  end

  def show
    initcontroller
    find_project
    if !params[:target_date].nil?
      targetuserids = UserManager::getProjectUserIds(@project)
      createUserEntryData(targetuserids)
    end
  end

private
  def find_project
    @project = Project.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def initcontroller
    if params[:target_date].nil?
      @targetdate = Date.today
    else
      @targetdate = params[:target_date].to_date
    end
    @firstdate = Date::new(@targetdate.year, @targetdate.month, 1)
    @lastdate = Date::new(@targetdate.year, @targetdate.month, -1)
    
    @daycollection = []
    convert_wday = [7, 1, 2, 3, 4, 5, 6]
    for targetindex in 0..(@lastdate - @firstdate) do
      targetdate = @firstdate + targetindex
      dayinfo = DayInfo::new
      dayinfo.date = targetdate
      #dayinfo.dayname = day_name(targetdate.wday) #targetdate.wday 曜日 0:日曜日〜6:土曜日)
      dayinfo.dayname = targetdate.strftime("%a")
      #Redmineの休業日をまず取得
      datecalc = Object.new
      datecalc.extend Redmine::Utils::DateCalculation
      dayinfo.isHoliday = datecalc.non_working_week_days.include?(convert_wday[targetdate.wday])
      #日本の祝日と論理和
      dayinfo.isHoliday = dayinfo.isHoliday | targetdate.holiday?(:jp) 
      @daycollection[targetindex] = dayinfo
    end
  end

  def createUserEntryData(targetuserids)
    targetusers = User.where(:id => targetuserids).order("lastname asc")

    @usercollection = []
    userindex = 0
    targetusers.each do |user|
      userinfo = UserInfo::new
      userinfo.info = user
      userinfo.timeentries = []

      targetindex = 0
      @daycollection.each do |dayinfo|
        timeentryinfo = TimeEntryInfo::new
        timeentryinfo.dayinfo = dayinfo
        if @project.nil?
          timeentryinfo.hour = TimeEntry.where(:user_id => user.id, :spent_on => dayinfo.date).sum(:hours).to_f
        else
          timeentryinfo.hour = TimeEntry.where(:user_id => user.id, :spent_on => dayinfo.date, :project_id => @project.id).sum(:hours).to_f
        end
        timeentryinfo.hour = timeentryinfo.hour.round(2)
        userinfo.timeentries[targetindex] = timeentryinfo
        targetindex += 1
      end

      @usercollection[userindex] = userinfo
      userindex += 1
    end
    #Rails.logger.info(targetdate.to_s)
  end
end
