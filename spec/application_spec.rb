require "#{File.dirname(__FILE__)}/spec_helper"

describe "main app" do
  include Rack::Test::Methods
  
  def app
    Temporaty::Application.new
  end
  
  describe "/" do
    it "returns hello world text" do
      get "/"
      last_response.body.should include("Hello, world")
    end
  end
end
