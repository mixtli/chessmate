require 'rspec'
require 'wrong'
require 'wrong/adapters/rspec'
#require 'bundler/setup'

require 'chess' # and any other gems you need
require 'chess/position'
RSpec.configure do |config|
  config.color_enabled = true
  config.formatter = 'documentation'
end

