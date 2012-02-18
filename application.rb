require "sinatra/base"

require "json"
require "redis"

module Temporaty
  class Application < Sinatra::Base
    get "/" do
      "Hello, world!"
    end
    
    post "/generate" do
      # Generate the alias
      new_alias = Helpers.generate_alias(params["email"])
      return 400 if new_alias.nil?
      
      # Return it
      {
        "alias" => "#{new_alias}@temporaty.com",
        "ttl" => Helpers::ALIAS_TTL.to_s
      }.to_json
    end
    
    error 400 do
      {
        "error" => "Bad Request",
        "message" => "Check your settings and verify that you are using a valid email address."
      }.to_json
    end
    error 404 do
      {
        "error" => "Not Found",
        "message" => "Verify you are hitting the correct URL"
      }.to_json
    end
  end
  
  class Helpers
    ALIAS_LENGTH = 8
    ALIAS_TTL = 24 * 60 * 60
    
    def self.generate_alias(email_address)
      return nil if email_address.nil? || !email_address.match(/^.*\@.*\..*$/)
      
      # Generate the alias
      key = rand(36**ALIAS_LENGTH).to_s(36)
      while self.redis.sismember("all_aliases", key) do
        key = rand(36**ALIAS_LENGTH).to_s(36)
        self.redis.incr("alias_collisions")
      end
      
      # Store the alias
      self.redis.setex("alias:#{key}", ALIAS_TTL, email_address.downcase)
      self.redis.sadd("all_aliases", key)
      
      key
    end
    def self.redis
      @redis ||= Redis.new(
        :host => ENV["REDIS_HOST"],
        :port => ENV["REDIS_PORT"],
        :password => ENV["REDIS_PASSWORD"]
      )
    end
  end
end
