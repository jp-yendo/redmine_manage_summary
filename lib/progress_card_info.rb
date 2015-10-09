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
      Project.where(:parent_id => nil, :status => 1).order("name asc").each do |project|
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
          ProgressCardInfo.setCardInfoIssueChild(project, version, nil, result)
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
    card_info.link = {:project_id => project.identifier}
    card_info.title = project.name

    projectIds = ProjectInfo.getProjectIds(project.id)
    issues = Issue.where(:project_id => projectIds, :parent => nil, :is_private => 0)
    ProgressCardInfo.setIssuesProgress(card_info, issues)
    
    return card_info
  end

  def self.getCardInfoVersion(project, version)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.type = "version"
    card_info.link = {:project_id => project.identifier, :version_id => version.id}
    card_info.title = version.name

    issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id, :is_private => 0)
    issues.each do |issue|
      if !issue.parent.nil? && !issue.parent.fixed_version_id.nil? && issue.parent.fixed_version_id == version.id
        issues.delete(issue)
      end
    end
    ProgressCardInfo.setIssuesProgress(card_info, issues)
    
    return card_info
  end

  def self.getCardInfoIssue(project, version, issue)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.issue = issue
    if issue.children.count > 0
      card_info.type = "issue-category"
      card_info.link = {:project_id => project.identifier, :parent_issue_id => issue.id}
      if !version.nil?
        card_info.link[:version_id] = version.id
      end
    else
      card_info.type = "issue"
      card_info.link = {:controller => 'issues', :action => 'show', :id => issue.id}
    end
    card_info.title = issue.subject + "(#" + issue.id.to_s + ")"

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

    total_count = 0
    total_progress = 0
    total_actual_progress = 0
    issues.each do |issue|
      info = ProgressCardInfo.getIssueProgress(issue)

      card_info.count_total_issue += info.count_total_issue
      card_info.count_closed_issue += info.count_closed_issue
      card_info.days_total_early += info.days_early
      card_info.days_total_delay += info.days_delay

      if card_info.days_max_early < info.days_max_early
        card_info.days_max_early = info.days_max_early
      end
      if card_info.days_max_delay < info.days_max_delay
        card_info.days_max_delay = info.days_max_delay
      end
      
      total_progress += info.progress
      total_actual_progress += info.actual_progress

      total_count += 1
    end
    
    if total_count > 0
      card_info.percent_progress = total_progress / total_count
      card_info.percent_actual_progress = total_actual_progress / total_count
    end
  end
  
  def self.getIssueProgress(issue)
    result  = IssueInfo::new

    if issue.start_date.nil? && issue.due_date.nil?
      result.isScheduled = false
    else
      result.isScheduled = true
    end

    #TODO:再帰呼出しでの分類対応
    #　　　子がある場合は自分を無視して子供のみ集計する
    if issue.children.count > 0
      result.count_total_issue = 0
      result.count_closed_issue = 0
      result.progress = 0
      result.actual_progress = 0
      result.days_early = 0
      result.days_delay = 0
      result.days_max_early = 0
      result.days_max_delay = 0

      total_count = 0
      total_progress = 0
      total_actual_progress = 0
      issue.children.each do |subissue|
        info = ProgressCardInfo.getIssueProgress(subissue)

        result.count_total_issue += info.count_total_issue
        result.count_closed_issue += info.count_closed_issue
        result.days_early += info.days_early
        result.days_delay += info.days_delay

        if result.days_max_early < info.days_max_early
          result.days_max_early = info.days_max_early
        end
        if result.days_max_delay < info.days_max_delay
          result.days_max_delay = info.days_max_delay
        end
        
        total_progress += info.progress
        total_actual_progress += info.actual_progress

        total_count += 1
      end

      if total_count > 0
        result.progress = total_progress / total_count
        result.actual_progress = total_actual_progress / total_count
      end
    else
      result.count_total_issue = 1
      if issue.status.is_closed == true
        result.count_closed_issue = 1
      else
        result.count_closed_issue = 0
      end
      result.progress = issue.done_ratio

      if issue.status.is_closed == true || issue.done_ratio == 100 || result.isScheduled == false
        if issue.status.is_closed == true
          result.progress = 100
        end
        result.actual_progress = result.progress
        result.days_early = 0
        result.days_delay = 0
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
          result.actual_progress = 100
        elsif start_date > today
          result.actual_progress = 0
        else
          temp_working_days = DayInfo.getWorkdays(start_date, today)
          result.actual_progress = temp_working_days * 100 / working_days
        end

        if result.progress > result.actual_progress
          result.days_early = working_days * (result.progress - result.actual_progress) / 100
          result.days_early = result.days_early.floor
          result.days_delay = 0
        elsif result.progress < result.actual_progress
          result.days_early = 0
          result.days_delay = working_days * (result.actual_progress - result.progress) / 100
          result.days_delay = result.days_delay.floor
        else
          result.days_early = 0
          result.days_delay = 0
        end
      end

      result.days_max_early = result.days_early
      result.days_max_delay = result.days_delay
    end

    return result
  end
  
  def self.setCardInfoProjectChild(project, cardinfolist)
    targetindex = cardinfolist.count

    #Sub Project
    subprojects = Project.all.where(:parent_id => project.id, :status => 1).order("name asc")
    subprojects.each do |subproject|
      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoProject(subproject)
      targetindex += 1
    end

    #Version
    versions = project.versions.where(:status => ['open','locked']).sort {|x,y| x.name <=> y.name}
    versions.each do |version|
      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoVersion(project, version)
      targetindex += 1
    end

    #Ticket
    ProgressCardInfo.setCardInfoIssueChild(project, nil, nil, cardinfolist)
  end

  def self.setCardInfoIssueChild(project, version, issue, cardinfolist)
    targetindex = cardinfolist.count
    
    #Ticket
    if version.nil? && issue.nil?
      issues = Issue.where(:project_id => project.id, :parent_id => nil, :is_private => 0)
    elsif !version.nil? && !issue.nil?
      issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id, :parent_id => issue.id, :is_private => 0)
    elsif !issue.nil?
      issues = Issue.where(:project_id => project.id, :parent_id => issue.id, :is_private => 0)
    elsif !version.nil?
      issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id, :is_private => 0)
    end
    issues.each do |issue|
      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoIssue(project, version, issue)
      targetindex += 1
    end
  end
end