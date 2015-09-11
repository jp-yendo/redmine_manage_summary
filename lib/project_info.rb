class ProjectInfo

  def self.getProjectIds(projectId, projectIds = nil)
    if projectIds.nil?
      result = [projectId]
    else
      result = projectIds
      result[result.count] = projectId
    end

    subprojects = Project.where(:parent_id => projectId)
    subprojects.each do |project|
      result = ProjectInfo.getProjectIds(project.id, result)
    end
    
    return result
  end
end
