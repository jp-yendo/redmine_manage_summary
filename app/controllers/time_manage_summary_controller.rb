class TimeManageSummaryController < ApplicationController
  unloadable

  DEFINE_DIGIT_OF_NUMBER = 2
  
  def index
    @filters_message = ""
    initTimeManage
    if !params[:target_date].nil?
      if checkTimeManage == false
        render "show"
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
      targetuserids = UserInfo.getProjectUserIds(@project.id)
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
    #get users object
    targetusers = User.where(:id => targetuserids).order("lastname asc")

    #get subproject
    if !@project.nil?
      targetProjects = ProjectInfo.getProjectIds(@project.id)
    else
      targetProjects = nil
    end
    
    #Users Ticket sum
    @usercollection = []
    userindex = 0
    targetusers.each do |user|
      userinfo = UserInfo::new
      userinfo.id = user.id
      userinfo.name = user.name

      #Estimated hours calc
      if @show_estimated_hours == "true"
        setTimeAssignments(userinfo, targetProjects)
      else
        userinfo.time_assignments = nil
      end

      #Entry hours sum
      if @show_entry_hours == "true"
        userinfo.time_entries = []
        targetindex = 0
        @daycollection.each do |dayinfo|
          timeinfo = TimeInfo::new
          timeinfo.dayinfo = dayinfo
          if targetProjects.nil?
            timeinfo.hour = TimeEntry.where(:user_id => user.id, :spent_on => dayinfo.date).sum(:hours).to_f
          else
            timeinfo.hour = TimeEntry.where(:user_id => user.id, :spent_on => dayinfo.date, :project_id => targetProjects).sum(:hours).to_f
          end
          timeinfo.hour = timeinfo.hour.round(DEFINE_DIGIT_OF_NUMBER)
          userinfo.time_entries[targetindex] = timeinfo
          targetindex += 1
        end
      else
        userinfo.time_entries = nil
      end

      @usercollection[userindex] = userinfo
      userindex += 1
    end
    
    #non user ticket sum
    #Estimated hours calc
    if @show_estimated_hours == "true"
      non_userinfo = UserInfo::new
      non_userinfo.id = nil
      non_userinfo.name = l(:managesummary_user_unallocated)
      non_userinfo.time_assignments = []

      setTimeAssignments(non_userinfo, targetProjects)

      #Entry hours dummy
      non_userinfo.time_entries = nil

      @usercollection[userindex] = non_userinfo
    end
  end
  
  def setTimeAssignments(userinfo, targetProjects = nil)
    userinfo.time_assignments = []

    default_hour = Setting.plugin_redmine_manage_summary['threshold_normalload'].to_f

    #get target ticket
    issue_where = "estimated_hours IS NOT NULL"
    issue_where += " and ("
    issue_where += "start_date between '#{@firstdate}' and '#{@lastdate}'"
    issue_where += " or due_date between '#{@firstdate}' and '#{@lastdate}'"
    issue_where += " or (start_date IS NOT NULL and due_date IS NOT NULL and start_date < '#{@firstdate}' and due_date > '#{@lastdate}')"
    issue_where += ")"
    if targetProjects.nil?
      calcIssue = Issue.where(:assigned_to_id => userinfo.id).where(issue_where)
    else
      calcIssue = Issue.where(:assigned_to_id => userinfo.id, :project_id => targetProjects).where(issue_where)
    end

    #Array reserve
    targetindex = 0
    @daycollection.each do |dayinfo|
      timeinfo = TimeInfo::new
      timeinfo.dayinfo = dayinfo
      timeinfo.hour = 0.00
      userinfo.time_assignments[targetindex] = timeinfo
      targetindex += 1
    end

    #add issue hour
    calcIssue.each do |issue|
      isHolidayWork = false
      day_hour = nil
      if !issue.start_date.nil? && !issue.due_date.nil?
        workdays = DayInfo.getWorkdays(issue.start_date, issue.due_date)
        if workdays < 1
          workdays = (issue.due_date - issue.start_date) + 1
          isHolidayWork = true
        end
        day_hour = issue.estimated_hours / workdays
        day_hour = day_hour.round(DEFINE_DIGIT_OF_NUMBER)
        start_date = issue.start_date
        end_date = issue.due_date
      elsif !issue.start_date.nil?
        day_hour = default_hour
        day_hour = day_hour.round(DEFINE_DIGIT_OF_NUMBER)
        start_date = issue.start_date
        end_date = DayInfo.calcProvisionalEndDate(start_date, issue.estimated_hours, day_hour)
      elsif !issue.due_date.nil?
        day_hour = default_hour
        day_hour = day_hour.round(DEFINE_DIGIT_OF_NUMBER)
        end_date = issue.due_date
        start_date = DayInfo.calcProvisionalStartDate(end_date, issue.estimated_hours, day_hour)
      end
      
      if !day_hour.nil?
        total_hour = issue.estimated_hours
        dayindex = 0
        while total_hour > 0 && (start_date + dayindex) <= @lastdate && (start_date + dayindex) >= @firstdate
          targetdate = start_date + dayindex
          timeinfo = userinfo.time_assignments.select{|timeinfo| timeinfo.dayinfo.date == targetdate}[0]
          if isHolidayWork == true || timeinfo.dayinfo.isHoliday == false
            if total_hour >= day_hour
              timeinfo.hour += day_hour
              total_hour -= day_hour
            else
              timeinfo.hour += total_hour
              total_hour = 0
            end
          end

          dayindex += 1
        end
      end
    end

    #round
    userinfo.time_assignments.each do |timeinfo|
      timeinfo.hour = timeinfo.hour.round(DEFINE_DIGIT_OF_NUMBER)
    end
    
    #date undecided ticket sum
    if targetProjects.nil?
      userinfo.date_undecided_hour = Issue.where(:assigned_to_id => userinfo.id, :due_date => nil, :start_date => nil).sum(:estimated_hours).to_f
    else
      userinfo.date_undecided_hour = Issue.where(:assigned_to_id => userinfo.id, :due_date => nil, :start_date => nil, :project_id => targetProjects).sum(:estimated_hours).to_f
    end
  end
end