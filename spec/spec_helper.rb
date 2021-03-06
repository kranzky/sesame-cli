# frozen_string_literal: true

require 'simplecov'
require 'awesome_print'
require 'byebug'

# rubocop:disable Style/ClassAndModuleChildren
module SimpleCov::Configuration
  def clean_filters
    @filters = []
  end
end
# rubocop:enable Style/ClassAndModuleChildren

SimpleCov.configure do
  clean_filters
  load_profile 'test_frameworks'
end

ENV['COVERAGE'] && SimpleCov.start do
  add_filter '/.rvm/'
end
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))

require 'rspec'

require 'sesame'

# Requires supporting files with custom matchers and macros, etc,
# in ./support/ and its subdirectories.
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
end
