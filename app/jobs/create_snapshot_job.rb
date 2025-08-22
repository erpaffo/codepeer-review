class CreateSnapshotJob < ApplicationJob
  queue_as :default
  
  def perform(project_id:, user_id:, snapshot_name:, description: nil)
    project = Project.find(project_id)
    user = User.find(user_id)
    
    # Trova il container Docker attivo per questo progetto
    container_name = "project_executor_#{project_id}"
    
    begin
      # Crea un archivio della cartella di lavoro
      archive_path = create_workspace_archive(container_name, project_id)
      
      # Crea il record della snapshot
      snapshot = SessionSnapshot.create!(
        user: user,
        project: project,
        name: snapshot_name,
        description: description
      )
      
      # Allega l'archivio
      snapshot.workspace_archive.attach(
        io: File.open(archive_path),
        filename: snapshot.filename,
        content_type: 'application/gzip'
      )
      
      # Aggiorna le statistiche
      update_snapshot_stats(snapshot, archive_path)
      
      # Pulisci il file temporaneo
      File.delete(archive_path) if File.exist?(archive_path)
      
      # Invia notifica di completamento
      Notification.create_snapshot_completed_notification(snapshot)
      
      Rails.logger.info "Snapshot created successfully: #{snapshot.id} for project #{project_id}"
      
    rescue => e
      Rails.logger.error "Failed to create snapshot for project #{project_id}: #{e.message}"
      raise e
    end
  end
  
  private
  
  def create_workspace_archive(container_name, project_id)
    # Percorso temporaneo per l'archivio
    temp_archive = "/tmp/workspace_#{project_id}_#{Time.current.to_i}.tar.gz"
    
    # Comando per creare l'archivio escludendo directory pesanti
    exclude_patterns = [
      '.git', 'node_modules', 'venv', '.venv', '__pycache__', 
      'dist', 'build', '.cache', '.mypy_cache', '.pytest_cache',
      '*.pyc', '*.pyo', '*.log', '*.tmp'
    ]
    
    exclude_args = exclude_patterns.map { |pattern| "--exclude=#{pattern}" }.join(' ')
    
    # Crea l'archivio dal container
    command = "docker exec #{container_name} bash -c 'cd /app && tar #{exclude_args} -czf #{temp_archive} .'"
    
    stdout, stderr, status = Open3.capture3(command)
    
    unless status.success?
      raise "Failed to create archive: #{stderr}"
    end
    
    # Copia l'archivio fuori dal container
    copy_command = "docker cp #{container_name}:#{temp_archive} #{temp_archive}"
    stdout, stderr, status = Open3.capture3(copy_command)
    
    unless status.success?
      raise "Failed to copy archive from container: #{stderr}"
    end
    
    temp_archive
  end
  
  def update_snapshot_stats(snapshot, archive_path)
    # Conta i file nell'archivio
    file_count = `tar -tzf #{archive_path} | wc -l`.strip.to_i
    
    # Dimensione dell'archivio
    archive_size = File.size(archive_path)
    
    snapshot.update!(
      file_count: file_count,
      archive_size: archive_size
    )
  end
end
