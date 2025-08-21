# -*- encoding: utf-8 -*-
# stub: spring 1.7.2 ruby lib

Gem::Specification.new do |s|
  s.name = "spring".freeze
  s.version = "1.7.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jon Leighton".freeze]
  s.date = "2016-07-01"
  s.description = "Preloads your application so things like console, rake and tests run faster".freeze
  s.email = ["j@jonathanleighton.com".freeze]
  s.executables = ["spring".freeze]
  s.files = ["bin/spring".freeze]
  s.homepage = "https://github.com/rails/spring".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "Rails application preloader".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<activesupport>.freeze, ["~> 4.2.0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<bump>.freeze, [">= 0"])
end
