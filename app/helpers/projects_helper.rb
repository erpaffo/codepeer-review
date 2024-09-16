module ProjectsHelper
  LANGUAGE_DETECTION = {
    '.c'     => 'c',
    '.cpp'   => 'cpp',
    '.py'    => 'python',
    '.js'    => 'javascript',
    '.rb'    => 'ruby',
    '.rs'    => 'rust',
    '.java'  => 'java'
  }.freeze

  def detect_languages
    detector = LanguageDetector.new(self)
    detected_languages = detector.detect_languages

    if detected_languages.any?
      self.update(languages: detected_languages)
    else
      errors.add(:base, 'No languages detected')
    end

    detected_languages # Assicurati di restituire l'array di linguaggi rilevati
  end
end
