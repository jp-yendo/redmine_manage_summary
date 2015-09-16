class ProcessCardInfo
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
  attr_accessor :days_early
  attr_accessor :days_delay

  def self.getCardInfoList(action, project = nil, version = nil)
    result = []

    if project.nil?
      targetindex = 0
      Project.where(:parent_id => nil).each do |project|
        result[targetindex] = ProcessCardInfo.getCardInfoProject(action, project)
        targetindex += 1
      end
    else
      if version.nil?
        ProcessCardInfo.setCardInfoProjectChild(action, project, result)
      else
        ProcessCardInfo.setCardInfoVersionChild(action, project, version, result)
      end
    end

    return result
  end

private
  def self.getCardInfoProject(action, project)
    card_info = ProcessCardInfo::new
    card_info.project = project
    card_info.type = "project"
    card_info.title = project.name
    card_info.link = {:controller => 'progress_summary', :action => action, :project_id => project.identifier}
    card_info.count_total_ticket = 0
    card_info.count_closed_ticket = 0
    card_info.percent_progress = 0
    card_info.days_early = 0
    card_info.days_delay = 0

    issues = Issue.where(:project_id => project.id)
    issues.each do |issue|
      if issue.children.count > 0
        #parent issue skip
        next
      end

      days_early, days_delay = ProcessCardInfo.getTicketProgress(issue)
    end
    
    return card_info
  end

  def self.getCardInfoVersion(action, project, version)
    card_info = ProcessCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.type = "version"
    card_info.title = version.name
    card_info.link = {:controller => 'progress_summary', :action => action, :project_id => project.identifier, :version => version.id}
    card_info.count_total_ticket = 0
    card_info.count_closed_ticket = 0
    card_info.percent_progress = 0
    card_info.days_early = 0
    card_info.days_delay = 0

    issues = Issue.where(:project_id => project.id, :fixed_version_id => version.id)
    issues.each do |issue|
      if issue.children.count > 0
        #parent issue skip
        next
      end

      days_early, days_delay = ProcessCardInfo.getTicketProgress(issue)
    end
    
    return card_info
  end

  def self.getCardInfoTicket(action, project, version, ticket)
    card_info = ProcessCardInfo::new
    card_info.project = project
    card_info.version = version
    card_info.ticket = ticket
    card_info.type = "ticket"
    card_info.title = ticket.subject + "(#" + ticket.id.to_s + ")"
    card_info.link = {:controller => 'issues', :action => 'show', :id => ticket.id}

    card_info.count_total_ticket = 1
    if ticket.status.is_closed == true
      card_info.count_closed_ticket = 1
    else
      card_info.count_closed_ticket = 0
    end
    card_info.percent_progress = ticket.done_ratio
    if ticket.status.is_closed == true || (ticket.start_date.nil? && ticket.due_date.nil?)
      card_info.days_early = 0
      card_info.days_delay = 0
    else
      #Calc
      days_early, days_delay = ProcessCardInfo.getTicketProgress(ticket)
      card_info.days_early = days_early
      card_info.days_delay = days_delay
    end

    return card_info
  end

  def self.getTicketProgress(ticket)
    days_early = 0
    days_delay = 0

    if ticket.status.is_closed == true || (ticket.start_date.nil? && ticket.due_date.nil?)
      days_early = 0
      days_delay = 0
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

      #ticket.done_ratio
    end
    
    return days_early, days_delay
  end
  
  def self.setCardInfoProjectChild(action, project, cardinfolist)
    targetindex = cardinfolist.count

    #Sub Project
    subprojects = Project.all.where(:parent_id => project.id)
    subprojects.each do |subproject|
      cardinfolist[targetindex] = ProcessCardInfo.getCardInfoProject(action, subproject)
      targetindex += 1
    end

    #Version
    project.versions.each do |version|
      cardinfolist[targetindex] = ProcessCardInfo.getCardInfoVersion(action, project, version)
      targetindex += 1
    end

    #Ticket
    ProcessCardInfo.setCardInfoVersionChild(action, project, nil, cardinfolist)
  end

  def self.setCardInfoVersionChild(action, project, version, cardinfolist)
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

      cardinfolist[targetindex] = ProcessCardInfo.getCardInfoTicket(action, project, version, issue)
      targetindex += 1
    end
  end
end