require './srv.rb'
require 'minitest/autorun'
require 'rack/test'
ENV['RACK_ENV'] = 'testing'

class Minitest::Test
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end
end
