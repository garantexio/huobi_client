require "huobi_client/client"
require "huobi_client/version"

module HuobiClient
  class << self
    def new(access, secret)
      HuobiClient::Client.new(access, secret)
    end
  end
end
