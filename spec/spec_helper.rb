# Base
require 'rubygems'
require 'bundler/setup'

# Testing
require 'rspec'

# Webmock
require 'webmock/rspec'
WebMock.disable_net_connect!

# Fluent
require "fluent/test"

# Rspec
RSpec.configure do |config|
  config.color = true
  config.order = :random
  config.warnings = false
end
