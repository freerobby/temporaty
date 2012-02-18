require "sinatra/base"

module Temporaty
  class Application < Sinatra::Base
    get "/" do
      "Hello, world!"
    end
  end
end