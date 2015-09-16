class ProgressCardInfo
  attr_accessor :type
  attr_accessor :title
  attr_accessor :link
  attr_accessor :project
  attr_accessor :version
  attr_accessor :ticket
  attr_accessor :comment
  attr_accessor :count_total_ticket
  attr_accessor :count_closed_ticket
  attr_accessor :percent_progress
  attr_accessor :percent_actual_progress
  attr_accessor :days_early
  attr_accessor :days_delay

  def self.getCardInfoList(project = nil, version = nil)
    result = []

    if project.nil?
      targetindex = 0
      Project.where(:parent_id => nil).each do |project|
        result[targetindex] = ProgressCardInfo.getCardInfoProject(project)
        targetindex += 1
      end
    else
      if version.nil?
        ProgressCardInfo.setCardInfoProjectChild(project, result)
      else
        ProgressCardInfo.setCardInfoVersionChild(project, version, result)
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

    issues = Issue.where(:project_id => project.id)
    ProgressCardInfo.setIssuesProgress(card_info, issues)
    
    return card_info
  end

  def self.getCardInfoVersion(project, version)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.type = "version"
    card_info.title = version.name
    card_info.link = {:controller => 'progress_summary', :action => @action, :project_id => project.identifier, :version => version.id}

    issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id)
    ProgressCardInfo.setIssuesProgress(card_info, issues)
    
    return card_info
  end

  def self.getCardInfoTicket(project, version, ticket)
    card_info = ProgressCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.ticket = ticket
    card_info.type = "ticket"
    card_info.title = ticket.subject + "(#" + ticket.id.to_s + ")"
    card_info.link = {:controller => 'issues', :action => 'show', :id => ticket.id}

    ProgressCardInfo.setIssuesProgress(card_info, [ticket])

    return card_info
  end

  def self.setIssuesProgress(card_info, issues)
    card_info.count_total_ticket = 0
    card_info.count_closed_ticket = 0
    card_info.percent_progress = 0
    card_info.percent_actual_progress = 0
    card_info.days_early = 0
    card_info.days_delay = 0

    total_count = 0
    total_progress = 0
    total_actual_progress = 0
    issues.each do |issue|
      if issue.children.count > 0
        #parent issue skip
        next
      end

      card_info.count_total_ticket += 1
      if issue.status.is_closed == true
        card_info.count_closed_ticket += 1
      end
      
      actual_progress, days_early, days_delay = ProgressCardInfo.getTicketProgress(issue)

      card_info.days_early += days_early
      card_info.days_delay += days_delay
      total_progress += issue.done_ratio
      total_actual_progress += actual_progress

      total_count += 1
    end
    
    if total_count > 0
      card_info.percent_progress = total_progress / total_count
      card_info.percent_actual_progress = total_actual_progress / total_count
    end
  end
  
  def self.getTicketProgress(ticket)
    if ticket.status.is_closed == true || ticket.done_ratio == 100 || (ticket.start_date.nil? && ticket.due_date.nil?)
      days_early = 0
      days_delay = 0
      actual_progress = 100
    else
      #Calc
      default_hour = Setting.plugin_redmine_manage_summary['threshold_normalload'].to_f
      if ticket.estimated_hours.nil?
        total_hour = 0
      else
        total_hour = ticket.estimated_hours
      end
      if ticket.start_date.nil?
        start_date = DayInfo.calcProvisionalStartDate(ticket.due_date, total_hour, default_hour)
      else        
        start_date = ticket.start_date
      end
      if ticket.due_date.nil?
        end_date = DayInfo.calcProvisionalEndDate(ticket.start_date, total_hour, default_hour)
      else        
        end_date = ticket.due_date
      end

      working_days = DayInfo.getWorkdays(start_date, end_date)
Rails.logger.info("--------------")
Rails.logger.info("working_days : " + working_days.to_s)
      today = Date.today
      if end_date < today
        actual_progress = 100
      elsif start_date > today
        actual_progress = 0
      else
        temp_working_days = DayInfo.getWorkdays(start_date, today)
        actual_progress = temp_working_days * 100 / working_days
      end

      if ticket.done_ratio > actual_progress
        days_early = working_days * (ticket.done_ratio - actual_progress) / 100
        days_early = days_early.floor
        days_delay = 0
      elsif ticket.done_ratio < actual_progress
        days_early = 0
        days_delay = working_days * (actual_progress - ticket.done_ratio) / 100
        days_delay = days_delay.floor
      else
        days_early = 0
        days_delay = 0
      end
    end

Rails.logger.info("working_days : " + working_days.to_s)
Rails.logger.info("actual_progress : " + actual_progress.to_s)
Rails.logger.info("days_early : " + days_early.to_s)
Rails.logger.info("days_delay : " + days_delay.to_s)
Rails.logger.info("--------------")
    
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
    ProgressCardInfo.setCardInfoVersionChild(project, nil, cardinfolist)
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

      cardinfolist[targetindex] = ProgressCardInfo.getCardInfoTicket(project, version, issue)
      targetindex += 1
    end
  end
end