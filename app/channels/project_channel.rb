class ProjectChannel < ApplicationCable::Channel
  def subscribed
    if params[:project_id].present?
      @project = Project.find_by(id: params[:project_id])
      if @project
        stream_for @project
        Rails.logger.info "Subscribed to ProjectChannel for Project ID: #{@project.id}"
      else
        reject
        Rails.logger.warn "ProjectChannel subscription rejected: Project ID #{params[:project_id]} not found."
      end
    else
      reject
      Rails.logger.warn "ProjectChannel subscription rejected: project_id parameter missing."
    end
  end

  def unsubscribed
    Rails.logger.info "Unsubscribed from ProjectChannel for Project ID: #{@project&.id}"
  end
end
