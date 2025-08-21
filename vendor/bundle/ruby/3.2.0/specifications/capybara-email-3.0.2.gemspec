# -*- encoding: utf-8 -*-
# stub: capybara-email 3.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "capybara-email".freeze
  s.version = "3.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Brian Cardarella".freeze]
  s.date = "2020-06-06"
  s.description = "Test your ActionMailer and Mailer messages in Capybara".freeze
  s.email = ["bcardarella@gmail.com".freeze, "brian@dockyard.com".freeze]
  s.homepage = "https://github.com/dockyard/capybara-email".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Test your ActionMailer and Mailer messages in Capybara".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<mail>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<capybara>.freeze, [">= 2.4", "< 4.0"])
  s.add_development_dependency(%q<actionmailer>.freeze, ["> 3.0"])
  s.add_development_dependency(%q<bourne>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
