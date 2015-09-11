class UserInfo
  attr_accessor :info
  attr_accessor :time_entries
  attr_accessor :time_assignments

   def self.getProjectUserIds(project, userids = nil)
    if userids.nil?
      result = []
    else
      result = userids
    end

    countindex = 0
    project.members.each do |member|
      if result.find { |userid| userid == member.user_id }.nil?
        result[countindex] = member.user_id
        countindex+=1
      end
    end

    subprojects = Project.where(:parent_id => project.id)
    subprojects.each do |project|
      result = UserInfo.getProjectUserIds(project, result)
    end

    return result
  end
 
  def self.getAllUserIds()
    result = []
    countindex = 0
    Project.all.each do |project|
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
