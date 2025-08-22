class SessionSnapshotsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_project
  before_action :set_snapshot, only: [:show, :destroy, :restore]
  before_action :ensure_user_can_access_snapshot, only: [:show, :destroy, :restore]
  
  def index
    @snapshots = @project.session_snapshots.for_user(current_user).recent
  end
  
  def show
    # Mostra i dettagli della snapshot
  end
  
  def new
    @snapshot = @project.session_snapshots.build
  end
  
  def create
    # Crea una nuova snapshot
    CreateSnapshotJob.perform_later(
      project_id: @project.id,
      user_id: current_user.id,
      snapshot_name: snapshot_params[:name],
      description: snapshot_params[:description]
    )
    
    redirect_to project_session_snapshots_path(@project), 
                notice: 'Snapshot creation started. You will be notified when it\'s ready.'
  end
  
  def restore
    # Ripristina una snapshot
    RestoreSnapshotJob.perform_later(
      project_id: @project.id,
      user_id: current_user.id,
      snapshot_id: @snapshot.id
    )
    
    redirect_to run_shell_project_path(@project), 
                notice: 'Snapshot restoration started. Your workspace will be updated shortly.'
  end
  
  def destroy
    @snapshot.destroy
    redirect_to project_session_snapshots_path(@project), 
                notice: 'Snapshot deleted successfully.'
  end
  
  private
  
  def set_project
    @project = Project.find(params[:project_id])
    
    # Verifica che l'utente abbia accesso al progetto
    unless @project.user == current_user || @project.collaborators.exists?(user: current_user)
      redirect_to projects_path, alert: 'You do not have access to this project.'
    end
  end
  
  def set_snapshot
    @snapshot = @project.session_snapshots.find(params[:id])
  end
  
  def ensure_user_can_access_snapshot
    unless @snapshot.user == current_user
      redirect_to project_session_snapshots_path(@project), 
                  alert: 'You can only access your own snapshots.'
    end
  end
  
  def snapshot_params
    params.require(:session_snapshot).permit(:name, :description)
  end
end
