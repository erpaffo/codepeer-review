namespace :ssl do
  desc "Generate self-signed SSL certificates for development"
  task :generate => :environment do
    ssl_dir = Rails.root.join('config', 'ssl')
    FileUtils.mkdir_p(ssl_dir)
    
    puts "Generating SSL certificates in #{ssl_dir}..."
    
    # Generate private key
    system("openssl genrsa -out #{ssl_dir}/key.pem 4096")
    
    # Generate certificate
    system("openssl req -new -x509 -key #{ssl_dir}/key.pem -out #{ssl_dir}/cert.pem -days 365 -subj '/C=IT/ST=Italy/L=Milan/O=CodePeer/CN=localhost'")
    
    puts "✅ SSL certificates generated successfully!"
    puts "🔑 Private key: #{ssl_dir}/key.pem"
    puts "📜 Certificate: #{ssl_dir}/cert.pem"
    puts "🌐 Access your site at: https://localhost:3001"
  end
  
  desc "Start Rails server with HTTPS enabled"
  task :server => :environment do
    puts "🚀 Starting Rails server with HTTPS..."
    puts "🔒 HTTP:  http://localhost:3000"
    puts "🔒 HTTPS: https://localhost:3001"
    puts "⚠️  Note: Self-signed certificate - accept the security warning in your browser"
    
    system("bundle exec rails server -p 3000 -b 0.0.0.0")
  end
  
  desc "Clean SSL certificates"
  task :clean => :environment do
    ssl_dir = Rails.root.join('config', 'ssl')
    if Dir.exist?(ssl_dir)
      FileUtils.rm_rf(ssl_dir)
      puts "🧹 SSL certificates removed from #{ssl_dir}"
    else
      puts "ℹ️  No SSL directory found"
    end
  end
end
