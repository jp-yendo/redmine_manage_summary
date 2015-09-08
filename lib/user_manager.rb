# To change this license header, choose License Headers in Project Properties.
# To change this template file, choose Tools | Templates
# and open the template in the editor.

class UserManager
  def initialize
    
  end
  
  def self.getProjectUserIds(project)
    result = []
    countindex = 0
    project.members.each do |member|
      result[countindex] = member.user_id
      countindex+=1
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
