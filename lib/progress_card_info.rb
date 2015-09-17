class ProgressCardInfo
  attr_accessor :type
  attr_accessor :title
  attr_accessor :link
  attr_accessor :project
  attr_accessor :version
  attr_accessor :issue
  attr_accessor :comment
  attr_accessor :count_total_issue
  attr_accessor :count_closed_issue
  attr_accessor :percent_progress
  attr_accessor :percent_actual_progress
  attr_accessor :days_total_early
  attr_accessor :days_max_early
  attr_accessor :days_total_delay
  attr_accessor :days_max_delay

  def self.getCardInfoList(project = nil, version = nil, issue = nil)
    result = []

    if project.nil?
      targetindex = 0
      Project.where(:parent_id => nil).each do |project|
        result[targetindex] = ProgressCardInfo.getCardInfoProject(project)
        targetindex += 1
      end
    else
      if !issue.nil?
        ProgressCardInfo.setCardInfoIssueChild(project, version, issue, result)
      else
        if version.nil?
          ProgressCardInfo.setCardInfoProjectChild(project, result)
        else
          ProgressCardInfo.setCardInfoVersionChild(project, version, result)
        end
      end
    end

    return result
  end

private
  def self.getCardInfoProject(project)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.type = "project"
    card_info.title = project.name
    card_info.link = {:controller => 'progress_summary', :action => @action, :project_id => project.identifier}

    projectIds = ProjectInfo.getProjectIds(project.id)
    issues = Issue.where(:project_id => projectIds)
    ProgressCardInfo.setIssuesProgress(card_info, issues)
    
    return card_info
  end

  def self.getCardInfoVersion(project, version)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.type = "version"
    card_info.title = version.name
    card_info.link = {:controller => 'progress_summary', :action => @action, :project_id => project.identifier, :version_id => version.id}

    issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id)
    ProgressCardInfo.setIssuesProgress(card_info, issues)
    
    return card_info
  end

  def self.getCardInfoIssue(project, version, issue)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.issue = issue
    card_info.type = "issue"
    card_info.title = issue.subject + "(#" + issue.id.to_s + ")"
    if issue.children.count > 0
      if version.nil?
        card_info.link = {:controller => 'progress_summary', :action => @action, :project_id => project.identifier, :parent_issue_id => issue.id}
      else
        card_info.link = {:controller => 'progress_summary', :action => @action, :project_id => project.identifier, :version_id => version.id, :parent_issue_id => issue.id}
      end
    else
      card_info.link = {:controller => 'issues', :action => 'show', :id => issue.id}
    end

    ProgressCardInfo.setIssuesProgress(card_info, [issue])

    return card_info
  end

  def self.setIssuesProgress(card_info, issues)
    card_info.count_total_issue = 0
    card_info.count_closed_issue = 0
    card_info.percent_progress = 0
    card_info.percent_actual_progress = 0
    card_info.days_total_early = 0
    card_info.days_max_early = 0
    card_info.days_total_delay = 0
    card_info.days_max_delay = 0

    #TODO:再帰呼出しでの分類対応
    #　　　子がある場合は自分を無視して子供のみ集計する
    
    total_count = 0
    total_progress = 0
    total_actual_progress = 0
    issues.each do |issue|
      if issue.children.count > 0
        #parent issue skip
        next
      end

      card_info.count_total_issue += 1
      if issue.status.is_closed == true
        card_info.count_closed_issue += 1
      end
      
      actual_progress, days_early, days_delay = ProgressCardInfo.getIssueProgress(issue)

      card_info.days_total_early += days_early
      card_info.days_total_delay += days_delay

      if card_info.days_max_early < days_early
        card_info.days_max_early = days_early
      end
      if card_info.days_max_delay < days_delay
        card_info.days_max_delay = days_delay
      end
      
      total_progress += issue.done_ratio
      total_actual_progress += actual_progress

      total_count += 1
    end
    
    if total_count > 0
      card_info.percent_progress = total_progress / total_count
      card_info.percent_actual_progress = total_actual_progress / total_count
    end
  end
  
  def self.getIssueProgress(issue)
    if issue.status.is_closed == true || issue.done_ratio == 100 || (issue.start_date.nil? && issue.due_date.nil?)
      days_early = 0
      days_delay = 0
      actual_progress = 100
    else
      #Calc
      default_hour = Setting.plugin_redmine_manage_summary['threshold_normalload'].to_f
      if issue.estimated_hours.nil?
        total_hour = 0
      else
        total_hour = issue.estimated_hours
      end
      if issue.start_date.nil?
        start_date = DayInfo.calcProvisionalStartDate(issue.due_date, total_hour, default_hour)
      else        
        start_date = issue.start_date
      end
      if issue.due_date.nil?
        end_date = DayInfo.calcProvisionalEndDate(issue.start_date, total_hour, default_hour)
      else        
        end_date = issue.due_date
      end

      working_days = DayInfo.getWorkdays(start_date, end_date)
      if working_days < 1
        working_days = (end_date - start_date) + 1
      end

      today = Date.today
      if end_date < today
        actual_progress = 100
      elsif start_date > today
        actual_progress = 0
      else
        temp_working_days = DayInfo.getWorkdays(start_date, today)
        actual_progress = temp_working_days * 100 / working_days
      end

      if issue.done_ratio > actual_progress
        days_early = working_days * (issue.done_ratio - actual_progress) / 100
        days_early = days_early.floor
        days_delay = 0
      elsif issue.done_ratio < actual_progress
        days_early = 0
        days_delay = working_days * (actual_progress - issue.done_ratio) / 100
        days_delay = days_delay.floor
      else
        days_early = 0
        days_delay = 0
      end
    end

    return actual_progress, days_early, days_delay
  end
  
  def self.setCardInfoProjectChild(project, cardinfolist)
    targetindex = cardinfolist.count

    #Sub Project
    subprojects = Project.all.where(:parent_id => project.id)
    subprojects.each do |subproject|
      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoProject(subproject)
      targetindex += 1
    end

    #Version
    project.versions.each do |version|
      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoVersion(project, version)
      targetindex += 1
    end

    #Ticket
    ProgressCardInfo.setCardInfoIssueChild(project, nil, nil, cardinfolist)
  end

  def self.setCardInfoVersionChild(project, version, cardinfolist)
    targetindex = cardinfolist.count

    #Ticket
    if version.nil?
      issues = Issue.where(:project_id => project.id, :fixed_version_id => nil)
    else
      issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id)
    end
    issues.each do |issue|
      if issue.children.count > 0
        #parent issue skip
        next
      end

      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoIssue(project, version, issue)
      targetindex += 1
    end
  end

  def self.setCardInfoIssueChild(project, version, issue, cardinfolist)
    targetindex = cardinfolist.count
    
    #Ticket
    if version.nil? && issue.nil?
      issues = Issue.where(:project_id => project.id, :fixed_version_id => nil, :parent_id => nil)
    elsif !issue.nil?
      issues = Issue.where(:project_id => project.id, :parent_id => issue.id)
    elsif !version.nil?
      issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id)
    end
    issues.each do |issue|
      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoIssue(project, version, issue)
      targetindex += 1
    end
  end
end