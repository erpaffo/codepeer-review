# -*- encoding: utf-8 -*-
# stub: omniauth-test 0.0.11 ruby lib

Gem::Specification.new do |s|
  s.name = "omniauth-test".freeze
  s.version = "0.0.11"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Your name".freeze]
  s.date = "2014-09-11"
  s.description = "Description of OmniauthTest.".freeze
  s.email = ["Your email".freeze]
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Summary of OmniauthTest.".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 3

  s.add_runtime_dependency(%q<omniauth-oauth2>.freeze, ["~> 1.2"])
  s.add_development_dependency(%q<rspec>.freeze, [">= 2.14.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
end
