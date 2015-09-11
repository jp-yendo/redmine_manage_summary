class TimeInfo
  attr_accessor :dayinfo
  attr_accessor :hour

  def getTimeCssStyleName()
    if @hour.nil?
      return ""
    end
    if @hour == 0
      return "notime"
    elsif @hour <= Setting.plugin_redmine_manage_summary['threshold_lowtime'].to_f
      return "lowtime"
    elsif @hour >= Setting.plugin_redmine_manage_summary['threshold_hardtime'].to_f
      return "hardtime"
    elsif @hour >= Setting.plugin_redmine_manage_summary['threshold_overtime'].to_f
      return "overtime"
    else
      return ""
    end
  end
end
