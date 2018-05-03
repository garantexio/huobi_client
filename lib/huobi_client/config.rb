require 'huobi_client/version'

module HuobiClient
  module Config
    USER_AGENT = "huobi client gem #{HuobiClient::VERSION}"
    BASE_URL = 'https://api.huobi.pro'.freeze
    SIGNATURE_VERSION = 2

  end
end
