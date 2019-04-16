# spec/spec_helper.rb
require 'rspec'
require 'capybara'
require 'capybara/dsl'
require 'dm-rspec'
require "rack_session_access"
require "rack_session_access/capybara"
require 'capybara/poltergeist'

ENV['RACK_ENV'] = 'test'

require File.expand_path '../../app.rb', __FILE__

module RSpecMixin
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
  Capybara.app = Sinatra::Application
  Capybara.app.use RackSessionAccess::Middleware
  Capybara.javascript_driver = :poltergeist
end

# For RSpec 2.x and 3.x
RSpec.configure do |c|
  c.include RSpecMixin
  c.include Capybara::DSL
	c.include(DataMapper::Matchers)

	DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/app_test.db")
  DataMapper.finalize
  User.auto_migrate!
  Friends.auto_migrate!
  Requests.auto_migrate!
  Group.auto_migrate!
  Event.auto_migrate!
  Comment.auto_migrate!
  Poll.auto_migrate!
  Vote.auto_migrate!
  Restaurant.auto_migrate!
  Dish.auto_migrate!
  Drink.auto_migrate!
  Tab.auto_migrate!

end