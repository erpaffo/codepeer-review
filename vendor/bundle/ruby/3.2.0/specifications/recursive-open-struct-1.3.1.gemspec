# -*- encoding: utf-8 -*-
# stub: recursive-open-struct 1.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "recursive-open-struct".freeze
  s.version = "1.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["William (B.J.) Snow Orvis".freeze]
  s.date = "2024-10-04"
  s.description = "RecursiveOpenStruct is a subclass of OpenStruct. It differs from\nOpenStruct in that it allows nested hashes to be treated in a recursive\nfashion. For example:\n\n    ros = RecursiveOpenStruct.new({ :a => { :b => 'c' } })\n    ros.a.b # 'c'\n\nAlso, nested hashes can still be accessed as hashes:\n\n    ros.a_as_a_hash # { :b => 'c' }\n".freeze
  s.email = "aetherknight@gmail.com".freeze
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/aetherknight/recursive-open-struct".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.4.10".freeze
  s.summary = "OpenStruct subclass that returns nested hash attributes as RecursiveOpenStructs".freeze

  s.installed_by_version = "3.4.10" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
  s.add_development_dependency(%q<pry>.freeze, [">= 0"])
  s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
  s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  s.add_runtime_dependency(%q<ostruct>.freeze, [">= 0"])
end
