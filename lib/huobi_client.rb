require "huobi_client/client"
require "huobi_client/version"

module HuobiClient
  class << self
    def new(access, secret, account_id=nil)
      HuobiClient::Client.new(access, secret, account_id)
    end
  end
end
