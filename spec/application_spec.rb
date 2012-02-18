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
  
  describe "/incoming" do
    it "forwards mail that can be looked up" do
      Pony.should_receive(:mail)
      the_alias = Temporaty::Helpers.generate_alias("test@asdf.com")
      post "/incoming", "to" => "#{the_alias}@temporaty.com"
    end
    it "does not forward mail that cannot be looked up" do
      Pony.should_not_receive(:mail)
      Temporaty::Helpers.send(:redis).flushdb
      post "/incoming", "to" => "bs@temporaty.com"
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
    describe "self.lookup_real_email" do
      it "returns email if found" do
        the_alias = Temporaty::Helpers.generate_alias("test@asdf.com")
        Temporaty::Helpers.lookup_real_email(the_alias).should == "test@asdf.com"
      end
      it "performs case insensitive find" do
        the_alias = Temporaty::Helpers.generate_alias("test@ASDF.com")
        Temporaty::Helpers.lookup_real_email(the_alias).should == "test@asdf.com"
      end
      it "returns nil if not found" do
        Temporaty::Helpers.send(:redis).flushdb
        Temporaty::Helpers.lookup_real_email("asdf").should be_nil
      end
    end
    
    describe "self.parse_address" do
      it "parses robby@freerobby.com out of 'Robby Grossman <robby@freerobby.com>'" do
        Temporaty::Helpers.send(:parse_address, "Robby Grossman <robby@freerobby.com>").should == "robby@freerobby.com"
      end
      it "parses robby@freerobby.com out of '<robby@freerobby.com>'" do
        Temporaty::Helpers.send(:parse_address, "<robby@freerobby.com>").should == "robby@freerobby.com"
      end
      it "parses robby@freerobby.com out of 'robby@freerobby.com'" do
        Temporaty::Helpers.send(:parse_address, "robby@freerobby.com").should == "robby@freerobby.com"
      end
      it "parses submit@paperphobic.com out of 'PaperPhobic <submit@paperphobic.com>'" do
        Temporaty::Helpers.send(:parse_address, "PaperPhobic <submit@paperphobic.com>").should == "submit@paperphobic.com"
      end
      it "parses receipts@submit.localhost out of 'receipts@submit.localhost'" do
        Temporaty::Helpers.send(:parse_address, "receipts@submit.localhost").should == "receipts@submit.localhost"
      end
    end
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
