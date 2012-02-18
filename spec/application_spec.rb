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
  
  describe "/generate" do
    describe "with no email" do
      before do
        post "/generate"
      end
      it "returns 400" do
        last_response.status.should == 400
      end
    end
    describe "with invalid email" do
      before do
        post "/generate", "email" => "fakeemail"
      end
      it "returns 400" do
        last_response.status.should == 400
      end
    end
    describe "with valid email" do
      before do
        post "/generate", "email" => "realemail@domain.com"
      end
      it "returns the alias" do
        the_alias = JSON.parse(last_response.body)["alias"]
        the_alias.should_not be_nil
        the_alias.length.should > 0
      end
      it "returns the ttl" do
        JSON.parse(last_response.body)["ttl"].should == Temporaty::Helpers::ALIAS_TTL.to_s
      end
      it "returns 200" do
        last_response.status.should == 200
      end
    end
  end
  
  describe "Helpers" do
    describe "self.generate_alias" do
      it "has length #{Temporaty::Helpers::ALIAS_LENGTH}" do
        Temporaty::Helpers.send(:generate_alias, "dummy@dummy.com").length.should == Temporaty::Helpers::ALIAS_LENGTH
      end
      it "has no uppercase letters" do
        the_alias = Temporaty::Helpers.send :generate_alias, "dummy@dummy.com"
        the_alias.downcase.should == the_alias
      end
      it "returns nil if not given an email address" do
        Temporaty::Helpers.send(:generate_alias, nil).should be_nil
      end
    end
  end
end
