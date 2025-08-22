class FileUploader < CarrierWave::Uploader::Base
  if Rails.env.test?
    storage :file
  else
    storage :fog
  end

  def store_dir
    user_folder_name = model.project.user.email.split('@').first
    project_folder_name = model.project.title.parameterize
    "uploads/#{user_folder_name}/#{project_folder_name}"
  end

  # Allow all file types for imports
  def extension_allowlist
    nil
  end
end
