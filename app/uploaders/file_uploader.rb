class FileUploader < CarrierWave::Uploader::Base
  storage :fog

  def store_dir
    user_folder_name = model.project.user.email.split('@').first
    project_folder_name = model.project.title.parameterize
    "uploads/#{user_folder_name}/#{project_folder_name}"
  end

  def extension_whitelist
    %w[jpg jpeg gif png txt pdf doc docx py c rb cpp css html]
  end
end
