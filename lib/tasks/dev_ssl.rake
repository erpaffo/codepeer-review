namespace :dev do
  desc 'Generate self-signed TLS certs for development (config/ssl/server.crt,key)'
  task :ssl do
    dir = Rails.root.join('config', 'ssl')
    FileUtils.mkdir_p(dir)
    key = dir.join('server.key')
    crt = dir.join('server.crt')

    if File.exist?(key) && File.exist?(crt)
      puts "SSL key/cert already exist: #{key}, #{crt}"
      next
    end

    subj = ENV['SSL_SUBJECT'] || '/C=IT/ST=Local/L=Local/O=Dev/OU=Dev/CN=localhost'
    system("openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout #{key} -out #{crt} -subj \"#{subj}\"")
    puts "Generated: #{key} and #{crt}"
  end
end


