# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://guides.rubygems.org/specification-reference/ for more options
  gem.name = "sesame-cli"
  gem.homepage = "http://github.com/kranzky/sesame-cli"
  gem.license = "UNLICENSE"
  gem.summary = %Q{Sesame is a simple password manager for the command-line.}
  gem.description = %Q{Sesame is a simple password manager for the command-line.}
  gem.email = "jasonhutchens@gmail.com"
  gem.authors = ["Jason Hutchens", "Jack Casey"]
  gem.required_ruby_version = "~> 2.1"
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc "Code coverage detail"
task :simplecov do
  ENV['COVERAGE'] = "true"
  Rake::Task['spec'].execute
end

task :default => :spec

require 'yard'
YARD::Rake::YardocTask.new
