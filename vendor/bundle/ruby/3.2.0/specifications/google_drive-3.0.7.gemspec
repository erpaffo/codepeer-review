# -*- encoding: utf-8 -*-
# stub: google_drive 3.0.7 ruby lib

Gem::Specification.new do |s|
  s.name = "google_drive".freeze
  s.version = "3.0.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hiroshi Ichikawa".freeze]
  s.date = "2021-04-13"
  s.description = "A library to read/write files/spreadsheets in Google Drive/Docs.".freeze
  s.email = ["gimite+github@gmail.com".freeze]
  s.homepage = "https://github.com/gimite/google-drive-ruby".freeze
  s.licenses = ["BSD-3-Clause".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "A library to read/write files/spreadsheets in Google Drive/Docs.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<nokogiri>.freeze, [">= 1.5.3", "< 2.0.0"])
  s.add_runtime_dependency(%q<google-apis-drive_v3>.freeze, [">= 0.5.0", "< 1.0.0"])
  s.add_runtime_dependency(%q<google-apis-sheets_v4>.freeze, [">= 0.4.0", "< 1.0.0"])
  s.add_runtime_dependency(%q<googleauth>.freeze, [">= 0.5.0", "< 1.0.0"])
  s.add_development_dependency(%q<test-unit>.freeze, [">= 3.0.0", "< 4.0.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0.8.0"])
  s.add_development_dependency(%q<rspec-mocks>.freeze, [">= 3.4.0", "< 4.0.0"])
end
