# -*- encoding: utf-8 -*-
# stub: kubeclient 4.12.0 ruby lib

Gem::Specification.new do |s|
  s.name = "kubeclient".freeze
  s.version = "4.12.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Alissa Bonas".freeze]
  s.date = "2024-06-18"
  s.description = "A client for Kubernetes REST api".freeze
  s.email = ["abonas@redhat.com".freeze]
  s.homepage = "https://github.com/abonas/kubeclient".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.10".freeze
  s.summary = "A client for Kubernetes REST api".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 1.6"])
  s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
  s.add_development_dependency(%q<minitest>.freeze, ["~> 5.15.0"])
  s.add_development_dependency(%q<minitest-rg>.freeze, [">= 0"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.0"])
  s.add_development_dependency(%q<vcr>.freeze, [">= 0"])
  s.add_development_dependency(%q<rubocop>.freeze, ["= 0.49.1"])
  s.add_development_dependency(%q<googleauth>.freeze, ["~> 0.5.1"])
  s.add_development_dependency(%q<mocha>.freeze, ["~> 1.5"])
  s.add_development_dependency(%q<openid_connect>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<net-smtp>.freeze, [">= 0"])
  s.add_development_dependency(%q<tzinfo-data>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<jsonpath>.freeze, ["~> 1.0"])
  s.add_runtime_dependency(%q<rest-client>.freeze, ["~> 2.0"])
  s.add_runtime_dependency(%q<recursive-open-struct>.freeze, ["~> 1.1", ">= 1.1.1"])
  s.add_runtime_dependency(%q<http>.freeze, [">= 3.0", "< 6.0"])
end
