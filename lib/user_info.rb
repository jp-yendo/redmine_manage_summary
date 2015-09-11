class UserInfo
  attr_accessor :id
  attr_accessor :name
  attr_accessor :time_assignments
  attr_accessor :time_entries
  attr_accessor :date_undecided_hour
  
  def self.getProjectUserIds(projectId)
    return UserInfo.getUserIds(projectId)
  end
 
  def self.getAllUserIds()
    return UserInfo.getUserIds()
  end

private
  def self.getUserIds(projectId = nil, userids = nil)
    if userids.nil?
      result = []
    else
      result = userids
    end

    if !projectId.nil?
      projectIds = ProjectInfo.getProjectIds(projectId)
      projects = Project.where(:id => projectIds)
    else
      projects = Project.all
    end

    countindex = 0
    projects.each do |project|
      project.members.each do |member|
        if result.find { |userid| userid == member.user_id }.nil?
          result[countindex] = member.user_id
          countindex+=1
        end
      end
    end

    return result
  end
end