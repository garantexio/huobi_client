require 'huobi_client/version'

module HuobiClient
  module Config
    USER_AGENT = "huobi client gem #{HuobiClient::VERSION}"
    API_URL = 'api.huobi.pro'.freeze
    URL_PREFIX = ''.freeze
#    API_URL = 'www.huobi.com.ru'.freeze
#    URL_PREFIX = '/api'.freeze
    BASE_URL = "https://#{API_URL}".freeze
    SIGNATURE_VERSION = 2

  end
end
