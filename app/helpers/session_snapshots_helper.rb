module SessionSnapshotsHelper
  def snapshot_status_badge(snapshot)
    if snapshot.workspace_archive.attached?
      content_tag :span, "Ready", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800"
    else
      content_tag :span, "Processing", class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 text-yellow-800"
    end
  end
  
  def snapshot_file_count_text(snapshot)
    if snapshot.file_count > 0
      pluralize(snapshot.file_count, 'file')
    else
      'No files'
    end
  end
  
  def snapshot_size_text(snapshot)
    if snapshot.archive_size > 0
      number_to_human_size(snapshot.archive_size)
    else
      'Unknown size'
    end
  end
  
  def snapshot_age_text(snapshot)
    time_ago_in_words(snapshot.created_at)
  end
  
  def can_manage_snapshot?(snapshot)
    current_user == snapshot.user
  end
  
  def snapshot_restore_confirmation_message
    "This will replace your current workspace with the files from this snapshot. " \
    "Any unsaved changes will be lost. Are you sure you want to continue?"
  end
end
