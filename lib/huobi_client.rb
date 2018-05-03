require "huobi_client/client"
require "huobi_client/version"

module HuobiClient
  class << self
    def new(access, secret)
      Huobi::Client.new(access, secret)
    end
  end
end
