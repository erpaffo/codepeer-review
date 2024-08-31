class FileUploader < CarrierWave::Uploader::Base
  storage :fog

  def store_dir
    user_folder_name = model.project.user.email.split('@').first
    project_folder_name = model.project.title.parameterize
    "uploads/#{user_folder_name}/#{project_folder_name}"
  end

  def extension_allowlist
    %w[rb py js ts java c cpp h cs php html css go rs swift kt sh bash zsh ps1 vb vba lua r pl pm asm sql scala clj cljs dart ex exs erl hrl hs lisp scm groovy jade pug m ruby php scss less jsx tsx vbproj csproj sln mxml xml xaml vue jsx tsx ini toml yaml yml json md dockerfile makefile gradle pro s tcl rkt ps scpt bashrc zshrc vimrc awk jsp lua]
  end
end
