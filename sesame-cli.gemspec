# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: sesame-cli 0.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "sesame-cli".freeze
  s.version = "0.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jason Hutchens".freeze, "Jack Casey".freeze]
  s.date = "2018-04-20"
  s.description = "Sesame is a simple password manager for the command-line.".freeze
  s.email = "jasonhutchens@gmail.com".freeze
  s.executables = ["sesame".freeze]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    ".document",
    "Gemfile",
    "Gemfile.lock",
    "README.md",
    "Rakefile",
    "UNLICENSE",
    "VERSION",
    "bin/sesame",
    "lib/sesame.rb",
    "lib/sesame/cave.rb",
    "lib/sesame/dict.rb",
    "lib/sesame/fail.rb",
    "lib/sesame/jinn.rb",
    "lib/sesame/lang/en.yml",
    "sesame.gemspec",
    "spec/spec_helper.rb"
  ]
  s.homepage = "http://github.com/kranzky/sesame-cli".freeze
  s.licenses = ["UNLICENSE".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.1".freeze)
  s.rubygems_version = "2.7.3".freeze
  s.summary = "Sesame is a simple password manager for the command-line.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<bases>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<clipboard>.freeze, ["~> 1.1"])
      s.add_runtime_dependency(%q<digest-crc>.freeze, ["~> 0.4"])
      s.add_runtime_dependency(%q<highline>.freeze, ["~> 1.7"])
      s.add_runtime_dependency(%q<i18n>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<rbnacl>.freeze, ["~> 5.0"])
      s.add_runtime_dependency(%q<rbnacl-libsodium>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<slop>.freeze, ["~> 4.6"])
      s.add_development_dependency(%q<awesome_print>.freeze, ["~> 1.8.0"])
      s.add_development_dependency(%q<byebug>.freeze, ["~> 10.0.1"])
      s.add_development_dependency(%q<jeweler>.freeze, ["~> 2.3.9"])
      s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.15"])
      s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
    else
      s.add_dependency(%q<bases>.freeze, ["~> 1.0"])
      s.add_dependency(%q<clipboard>.freeze, ["~> 1.1"])
      s.add_dependency(%q<digest-crc>.freeze, ["~> 0.4"])
      s.add_dependency(%q<highline>.freeze, ["~> 1.7"])
      s.add_dependency(%q<i18n>.freeze, ["~> 1.0"])
      s.add_dependency(%q<rbnacl>.freeze, ["~> 5.0"])
      s.add_dependency(%q<rbnacl-libsodium>.freeze, ["~> 1.0"])
      s.add_dependency(%q<slop>.freeze, ["~> 4.6"])
      s.add_dependency(%q<awesome_print>.freeze, ["~> 1.8.0"])
      s.add_dependency(%q<byebug>.freeze, ["~> 10.0.1"])
      s.add_dependency(%q<jeweler>.freeze, ["~> 2.3.9"])
      s.add_dependency(%q<rdoc>.freeze, ["~> 6.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.15"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<bases>.freeze, ["~> 1.0"])
    s.add_dependency(%q<clipboard>.freeze, ["~> 1.1"])
    s.add_dependency(%q<digest-crc>.freeze, ["~> 0.4"])
    s.add_dependency(%q<highline>.freeze, ["~> 1.7"])
    s.add_dependency(%q<i18n>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rbnacl>.freeze, ["~> 5.0"])
    s.add_dependency(%q<rbnacl-libsodium>.freeze, ["~> 1.0"])
    s.add_dependency(%q<slop>.freeze, ["~> 4.6"])
    s.add_dependency(%q<awesome_print>.freeze, ["~> 1.8.0"])
    s.add_dependency(%q<byebug>.freeze, ["~> 10.0.1"])
    s.add_dependency(%q<jeweler>.freeze, ["~> 2.3.9"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 6.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.15"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
  end
end

