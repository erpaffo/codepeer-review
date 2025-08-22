class RestoreSnapshotJob < ApplicationJob
  queue_as :default
  
  def perform(project_id:, user_id:, snapshot_id:)
    project = Project.find(project_id)
    user = User.find(user_id)
    snapshot = SessionSnapshot.find(snapshot_id)
    
    # Verifica che l'utente abbia accesso a questa snapshot
    unless snapshot.user_id == user_id
      raise "User #{user_id} cannot access snapshot #{snapshot_id}"
    end
    
    container_name = "project_executor_#{project_id}"
    
    begin
      # Scarica l'archivio dalla snapshot
      archive_path = download_snapshot_archive(snapshot)
      
      # Ferma eventuali processi attivi nel container
      stop_active_processes(container_name)
      
      # Pulisci la cartella di lavoro (mantieni file di configurazione importanti)
      clean_workspace(container_name)
      
      # Ripristina i file dalla snapshot
      restore_workspace(container_name, archive_path)
      
      # Riavvia il container se necessario
      restart_container_if_needed(container_name)
      
      # Pulisci il file temporaneo
      File.delete(archive_path) if File.exist?(archive_path)
      
      # Invia notifica di ripristino
      Notification.create_snapshot_restored_notification(snapshot)
      
      Rails.logger.info "Snapshot #{snapshot_id} restored successfully for project #{project_id}"
      
    rescue => e
      Rails.logger.error "Failed to restore snapshot #{snapshot_id} for project #{project_id}: #{e.message}"
      raise e
    end
  end
  
  private
  
  def download_snapshot_archive(snapshot)
    # Percorso temporaneo per l'archivio
    temp_archive = "/tmp/restore_#{snapshot.id}_#{Time.current.to_i}.tar.gz"
    
    # Scarica l'archivio dalla snapshot
    File.open(temp_archive, 'wb') do |file|
      file.write(snapshot.workspace_archive.download)
    end
    
    temp_archive
  end
  
  def stop_active_processes(container_name)
    # Termina processi attivi (es. make, gcc, etc.)
    command = "docker exec #{container_name} bash -c 'pkill -f \"make\\|gcc\\|python\\|node\" || true'"
    Open3.capture3(command)
  end
  
  def clean_workspace(container_name)
    # Lista dei file da mantenere (configurazioni importanti)
    keep_files = ['.env', '.gitignore', 'docker-compose.yml', 'Dockerfile']
    
    # Pulisci tutto tranne i file da mantenere
    keep_files.each do |file|
      # Sposta temporaneamente i file importanti
      command = "docker exec #{container_name} bash -c 'if [ -f /app/#{file} ]; then mv /app/#{file} /tmp/#{file}; fi'"
      Open3.capture3(command)
    end
    
    # Rimuovi tutto dalla cartella di lavoro
    command = "docker exec #{container_name} bash -c 'rm -rf /app/* /app/.[^.]*'"
    Open3.capture3(command)
    
    # Ripristina i file importanti
    keep_files.each do |file|
      command = "docker exec #{container_name} bash -c 'if [ -f /tmp/#{file} ]; then mv /tmp/#{file} /app/#{file}; fi'"
      Open3.capture3(command)
    end
  end
  
  def restore_workspace(container_name, archive_path)
    # Copia l'archivio nel container
    copy_command = "docker cp #{archive_path} #{container_name}:/tmp/workspace.tar.gz"
    stdout, stderr, status = Open3.capture3(copy_command)
    
    unless status.success?
      raise "Failed to copy archive to container: #{stderr}"
    end
    
    # Estrai l'archivio nella cartella di lavoro
    extract_command = "docker exec #{container_name} bash -c 'cd /app && tar -xzf /tmp/workspace.tar.gz && rm /tmp/workspace.tar.gz'"
    stdout, stderr, status = Open3.capture3(extract_command)
    
    unless status.success?
      raise "Failed to extract archive in container: #{stderr}"
    end
  end
  
  def restart_container_if_needed(container_name)
    # Riavvia il container se è fermo
    status_command = "docker ps --filter name=#{container_name} --format '{{.Status}}'"
    status = `#{status_command}`.strip
    
    if status.empty?
      # Container fermo, riavvialo
      start_command = "docker start #{container_name}"
      stdout, stderr, status = Open3.capture3(start_command)
      
      unless status.success?
        Rails.logger.warn "Failed to restart container #{container_name}: #{stderr}"
      end
    end
  end
end
