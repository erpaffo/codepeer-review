module ProjectsHelper
  def detect_language(filename)
    case File.extname(filename)
    when '.js'
      'javascript'
    when '.rb'
      'ruby'
    when '.py'
      'python'
    when '.md'
      'markdown'
    when '.c'
      'c'
    when '.cpp'
      'cpp'
    when '.rs'
      'rust'
    when '.html'
      'html'
    when '.css'
      'css'
    when '.xml'
      'xml'
    when '.txt'
      'plaintext'
    else
      'plaintext'
    end
  end
end
