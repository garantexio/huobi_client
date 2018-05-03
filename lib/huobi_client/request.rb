require 'base64'
require 'openssl'
require 'faraday'
require 'faraday_middleware'
require 'huobi_client/config'
require 'huobi_client/response'

module HuobiClient
  module Request
    def get(path, options={})
      connect(:get, path, options)
    end

    def post(path, options={})
      # options.merge! created: created_at, access_key: @key
      connect(:post, path, options)
    end

    private

    def build_and_sign(method, path, options, params)
      params.merge! options if method.upcase == :GET

      str = Faraday::FlatParamsEncoder.encode(params.sort)

      sign "#{method.to_s.upcase}\napi.huobi.pro\n#{path}\n#{str}"
    end

    def connect(method, path, options)
      options.compact!
      params = {
        AccessKeyId: @access,
        SignatureMethod: 'HmacSHA256',
        SignatureVersion: HuobiClient::Config::SIGNATURE_VERSION,
        Timestamp: Time.now.getutc.strftime("%Y-%m-%dT%H:%M:%S")
      }.transform_keys { |key| key.to_s }

      params['Signature'] = build_and_sign(method, path, options, params)

      options.merge! params if method.upcase == :GET

      path = "#{path}?#{Faraday::FlatParamsEncoder.encode(params)}" if method.upcase == :POST

      # ap options
      Response.new(connection.send(method, path, options))
    end

    def connection
      options = {
        url: HuobiClient::Config::BASE_URL,
        headers:  {
          user_agent: HuobiClient::Config::USER_AGENT
        },
      }

      @connection ||= Faraday.new(options) do |conn|
        conn.request  :json
        conn.response :json, :content_type => "application/json"
        conn.adapter  Faraday.default_adapter
      end
    end

    def sign(str)
      Base64.encode64(OpenSSL::HMAC.digest('sha256', @secret.to_s, str)).strip()
    end


  end
end
