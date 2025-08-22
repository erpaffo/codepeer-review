class GithubImportJob < ApplicationJob
  queue_as :default

  # args: {
  #   repo_url: String,
  #   project_id: Integer (preferred) OR
  #   user_id: Integer, title: String, description: String, visibility: String
  # }
  def perform(args)
    require 'open-uri'
    require 'zip'
    require 'fileutils'

    repo_url     = args.fetch(:repo_url).to_s.strip
    project      = resolve_project(args)

    owner, repo, ref = parse_github_repo(repo_url)
    zip_url = "https://api.github.com/repos/#{owner}/#{repo}/zipball/#{ref || 'HEAD'}"

    Dir.mktmpdir('zip_import_') do |dir|
      zip_path = File.join(dir, 'repo.zip')
      download_zip(zip_url, zip_path)

      extract_dir = File.join(dir, 'extract')
      FileUtils.mkdir_p(extract_dir)
      extract_zip(zip_path, extract_dir)

      top = Dir.children(extract_dir).first
      root = top ? File.join(extract_dir, top) : extract_dir

      import_files_from(root, project)
    end
  end

  private

  def resolve_project(args)
    if args[:project_id]
      Project.find(args[:project_id])
    else
      user = User.find(args.fetch(:user_id))
      Project.create!(
        user: user,
        title: args.fetch(:title),
        description: args[:description].to_s,
        visibility: (args[:visibility].presence || 'private')
      )
    end
  end

  def parse_github_repo(url)
    # Supports: https://github.com/owner/repo(.git)[#ref]
    m = url.match(%r{github\.com[:/](?<owner>[^/]+)/(?<repo>[^/#\.]+)(?:\.git)?(?:#(?<ref>[^/]+))?}i)
    raise ArgumentError, 'Invalid GitHub URL' unless m
    [m[:owner], m[:repo], m[:ref]]
  end

  def download_zip(zip_url, dest)
    headers = {}
    if (token = ENV['GITHUB_ACCESS_TOKEN']).present?
      headers['Authorization'] = "token #{token}"
      headers['User-Agent'] = 'CodePeer'
      headers['Accept'] = 'application/vnd.github+json'
    end
    URI.open(zip_url, **headers) do |io|
      File.open(dest, 'wb') { |f| IO.copy_stream(io, f) }
    end
  end

  def extract_zip(zip_path, target_dir)
    Zip::File.open(zip_path) do |zip_file|
      zip_file.each do |entry|
        dest = File.join(target_dir, entry.name)
        FileUtils.mkdir_p(File.dirname(dest))
        zip_file.extract(entry, dest) unless File.exist?(dest)
      end
    end
  end

  def import_files_from(root_dir, project)
    exclusions = [
      %r{^\.git/}, %r{(^|/)node_modules(/|$)}, %r{(^|/)vendor/bundle(/|$)},
      %r{(^|/)dist(/|$)}, %r{(^|/)build(/|$)}, %r{(^|/)\.next(/|$)}, %r{(^|/)target(/|$)},
      %r{(^|/)coverage(/|$)}, %r{(^|/)__pycache__(/|$)}, %r{(^|/)\.venv(/|$)},
      %r{(^|/)env(/|$)}, %r{(^|/)\.cache(/|$)}, %r{(^|/)\.gradle(/|$)},
      %r{(^|/)Pods(/|$)}, %r{(^|/)DerivedData(/|$)}
    ]

    Dir.glob(File.join(root_dir, '**', '*'), File::FNM_DOTMATCH).each do |path|
      next unless File.file?(path)
      rel = path.sub(/^#{Regexp.escape(root_dir)}\//, '')

      # Skip dot entries
      next if rel == '.' || rel == '..'
      # Skip excluded patterns
      next if exclusions.any? { |rx| rel.match?(rx) }

      # Stage into tmp to keep uploader paths flat
      dest = File.join(Rails.root, 'tmp', rel)
      FileUtils.mkdir_p(File.dirname(dest))
      FileUtils.cp(path, dest)

      begin
        pf = project.project_files.new(file: File.open(dest))
        unless pf.save
          Rails.logger.warn "Skipped import file #{rel}: #{pf.errors.full_messages.join(', ')}"
        end
      rescue => e
        Rails.logger.warn "Failed to import file #{rel}: #{e.message}"
      end
    end
  end
end



