class LanguageDetector
  LANGUAGE_EXTENSIONS = {
    'rb' => 'Ruby',
    'py' => 'Python',
    'js' => 'JavaScript',
    'html' => 'HTML',
    'css' => 'CSS',
    'c' => 'C',
    'cpp' => 'C++',
    'java' => 'Java',
    'sh' => 'Shell',
    'php' => 'PHP',
    'swift' => 'Swift',
    'ts' => 'TypeScript',
    'go' => 'Go',
    'rs' => 'Rust'
  }

  def initialize(project)
    @project = project
  end

  def detect_languages
    languages = @project.project_files.map do |file|
      extension = File.extname(file.file_identifier).delete('.').downcase
      LANGUAGE_EXTENSIONS[extension]
    end

    languages.compact.uniq
  end
end
