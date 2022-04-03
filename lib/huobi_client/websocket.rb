require 'faye/websocket'
require 'base64'
require 'openssl'
require 'json'

=begin
EXAMPLES OF USAGE

require "huobi_client/websocket"
require "eventmachine"
require "zlib"
open_p  = proc { p 'ws connected' }
message = proc { |e| p "message:#{e}" }
error   = proc { |e| p "error:#{e}" }
close   = proc { p 'ws closed' }
log = proc { |e| p "log:#{e}" }
ping = proc { |e| p "ping:#{e}" }
cbs = { open: open_p, message: message, error: error, close: close, log: log, ping: ping }

# 1 - instance methods(subscribe, unsubscribe, request)
#     available topics: :candlestick, :ticker, :depth, :by_price_incremental, :by_price_refresh, :best_bid_offer, :trade_detail, :details, :etp, :order_updates, :trade_clearing, :accounts_update
EM.run do
  ws = HuobiClient::WebSocket.new({topic: :accounts_update, access_key: 'YOUR KEY', secret: 'YOUR SECRET' })
  ws.subscribe(params: {}, callbacks_hash: cbs)
end

# 2 - class methods(candlestick, ticker, depth, by_price_incremental, by_price_refresh, best_bid_offer, trade_detail, details, etp, order_updates, trade_clearing, accounts_update )
EM.run do
  HuobiClient::WebSocket.candlestick(
    command: :subscribe,
    params: {
      params: {symbol: 'btcusdt', period: '5min'},
      callbacks_hash: cbs
    }
  )
end

# 3 - class method run for multiply requests
EM.run do
  HuobiClient::WebSocket.run([
    {
      command: :subscribe,
      options: {topic: :best_bid_offer},
      params: { params: {}, callbacks_hash: cbs}
    },
    {
      command: :subscribe,
      options: {topic: :candlestick},
      params: { params: {symbol: 'btcusdt', period: '5min'}, callbacks_hash: cbs }
    },
    {
      command: :subscribe,
      options: {topic: :accounts_update, access_key: 'YOUR KEY', secret: 'YOUR SECRET'},
      params: { params: {}, callbacks_hash: cbs }
    }
  ])
end
=end

module HuobiClient
  class WebSocket
    class Error < StandardError; end

    TOPICS = {
      # Based on docs: https://huobiapi.github.io/docs/spot/v1/en/#websocket-market-data
      candlestick: { params: { symbol: 'btcusdt', period: '1min' },
                     url_endpoint: 'ws',
                     request_template: '{"$req_type$":"market.$symbol$.kline.$period$","id":"$id$"}',
                     zipped_answer: true },
      ticker: { params: { symbol: 'btcusdt' },
                url_endpoint: 'ws',
                request_template: '{"$req_type$":"market.$symbol$.ticker"}',
                zipped_answer: true },
      depth: { params: { symbol: 'btcusdt', type: 'step0' },
               url_endpoint: 'ws',
               request_template: '{"$req_type$":"market.$symbol$.depth.$type$","id":"$id$"}',
               zipped_answer: true },
      by_price_incremental: { params: { symbol: 'btcusdt', levels: 5 },
                              url_endpoint: 'feed',
                              request_template: '{"$req_type$":"market.$symbol$.mbp.$levels$","id":"$id$"}',
                              zipped_answer: true },
      by_price_refresh: { params: { symbol: 'btcusdt', levels: 5 },
                          url_endpoint: 'ws',
                          request_template: '{"$req_type$":"market.$symbol$.mbp.refresh.$levels$","id":"$id$"}',
                          zipped_answer: true },
      best_bid_offer: { params: { symbol: 'btcusdt' },
                        url_endpoint: 'ws',
                        request_template: '{"$req_type$":"market.$symbol$.bbo","id":"$id$"}',
                        zipped_answer: true },
      trade_detail: { params: { symbol: 'btcusdt' },
                      url_endpoint: 'ws',
                      request_template: '{"$req_type$":"market.$symbol$.trade.detail","id":"$id$"}',
                      zipped_answer: true },
      details: { params: { symbol: 'btcusdt' },
                 url_endpoint: 'ws',
                 request_template: '{"$req_type$":"market.$symbol$.detail","id":"$id$"}',
                 zipped_answer: true },
      etp: { params: { symbol: 'btcusdt' },
             url_endpoint: 'ws',
             request_template: '{"$req_type$":"market.$symbol$.etp","id":"$id$"}',
             zipped_answer: true },

      # Based on doc: https://open.huobigroup.com/?name=ws-order-update-v2
      order_updates: { params: { symbol: 'btcusdt' },
                       url_endpoint: 'ws/v2',
                       request_template: '{"action":"$req_type$","ch":"orders#$symbol$"}',
                       zipped_answer: false,
                       auth_required: true },
      trade_clearing: { params: { symbol: 'btcusdt', mode: 0 },
                        url_endpoint: 'ws/v2',
                        request_template: '{"action":"$req_type$","ch":"trade.clearing#$symbol$#$mode$"}',
                        zipped_answer: false,
                        auth_required: true },
      accounts_update: { params: { mode: 0 },
                         url_endpoint: 'ws/v2',
                         request_template: '{"action":"$req_type$","ch":"accounts.update#$mode$"}',
                         zipped_answer: false,
                         auth_required: true }
    }.freeze

    AUTH_REQ_TEMPLATE = {
      action: 'req',
      ch: 'auth',
      params: {
        authType: 'api',
        accessKey: '$access_key$',
        signatureMethod: 'HmacSHA256',
        signatureVersion: '2.1',
        timestamp: '$timestamp$', # 2022-02-17T11:49:41
        signature: '$signature$'  # kYOhol4ccJj8GM24zrqd6l6ny8MHV9eRN3KcOaWxCzs=
      }
    }.to_json

    AUTH_SIGNATURE_STR = "GET\napi.huobi.pro\n/ws/v2\naccessKey=$access_key$&signatureMethod=HmacSHA256&signatureVersion=2.1&timestamp=$timestamp$"

    def initialize(options = {})
      @topic = options[:topic]
      raise Error, 'Missed or wrong topic' unless TOPICS.keys.include?(@topic)

      @aws = options[:aws]
      @access_key = options[:access_key]
      @secret = options[:secret]
      @websocket = create_websocket
      @req_type = 'sub'
      @params = {}
      @callbacks_hash = options[:callbacks_hash] || []
      attach_callbacks
    end

    def subscribe(params:, callbacks_hash:)
      run_command(command: 'sub', params: params, callbacks_hash: callbacks_hash)
    end

    def unsubscribe(params:, callbacks_hash:)
      run_command(command: 'unsub', params: params, callbacks_hash: callbacks_hash)
    end

    def request(params:, callbacks_hash:)
      run_command(command: 'req', params: params, callbacks_hash: callbacks_hash)
    end

    def run_command(command:, params:, callbacks_hash:)
      @req_type = command
      @params = params
      @callbacks_hash = callbacks_hash
      attach_callbacks_and_send_to_websocket
    end

    def self.run(commands)
      case commands
      when Array
        commands.map do |command_hash|
          new(command_hash[:options]).public_send(command_hash[:command], **command_hash[:params])
        end
      when Hash
        new(commands[:options]).public_send(commands[:command], **commands[:params])
      else
        raise Error, 'Wrong params - array of commands hashes or commands hash is needed'
      end
    end

    # EXAMPLE
    # cbs = { open: on_open, message: on_message, error: on_error, close: on_close, ping: on_ping, log: on_log }
    # topics = []
    # topics << { topic: :depth, params: { symbol: 'btcusdt', type: 'step0' }}
    # topics << { topic: :ticker, params: { symbol: 'btcusdt' }}
    #                    ANY PUBLIC TOPIC
    # command = { options: { topic: :depth, callbacks_hash: cbs}, topics: topics }
    def self.subscribe_in_single_socket(command)
      raise 'Hash with options and topics with params expected' unless command.is_a?(Hash)

      huobi_ws = new(command[:options])
      topics = command[:topics]
      topics.each do |topic_hash|
        huobi_ws.send_to_websocket(req_type: 'sub', params: topic_hash)
      end
    end

    def self.method_missing(method_name, *args)
      if TOPICS.keys.include?(method_name.to_sym)
        command_hash = args[0]
        command_hash.merge!(options: { topic: method_name })
        run(command_hash)
      else
        super
      end
    end

    def self.respond_to_missing?(method_name)
      TOPICS.keys.include?(method_name.to_sym) || super
    end

    def send_to_websocket(req_type:, params:)
      topic = params[:topic] || @topic
      message = stream_request_data(req_type: req_type, topic: topic, params: params.reject { |k, _| k == :topic} )
      @callbacks_hash[:log]&.call("Send: #{message}")
      @websocket.send(message)
    end

    private

    def attach_callbacks_and_send_to_websocket
      attach_callbacks
      auth_required?(@topic) ? send_auth : send_to_websocket(req_type: @req_type, params: @params)
    end

    def attach_callbacks
      @callbacks_hash.each_pair do |key, method|
        next if key == :log

        @websocket.on(key) do |event|
          case key
          when :message
            process_message(message: event)
          else
            method.call(event)
          end
        end
      end
    end

    def stream_request_data(req_type:, topic:, params:)
      default_params = TOPICS[topic][:params]
      needed_keys = default_params.keys
      merged_params = default_params.merge(params).slice(*needed_keys)
      id = params[:req_id] || "#{object_id}_#{req_type}_#{(Time.now.to_f * 1000).to_i}"
      merged_params.merge!(req_type: req_type, id: id)

      request_template = TOPICS[topic][:request_template].dup
      substitude(str: request_template, subst_hash: merged_params)
    end

    def stream_auth_request_data
      timestamp = Time.now.getutc.strftime('%Y-%m-%dT%H:%M:%S')
      request_template = AUTH_REQ_TEMPLATE.dup
      params = {
        access_key: @access_key,
        timestamp: timestamp,
        signature: signature(timestamp)
      }
      substitude(str: request_template, subst_hash: params)
    end

    def create_websocket
      url = stream_url(@topic)
      Faye::WebSocket::Client.new(url)
    end

    def stream_url(topic)
      aws_suffix = @aws ? '-aws' : ''
      endpoint = TOPICS[topic][:url_endpoint]
      "wss://api#{aws_suffix}.huobi.pro/#{endpoint}"
    end

    def process_message(message:)
      methods = @callbacks_hash
      message = zipped_answer?(@topic) ? Zlib::GzipReader.new(StringIO.new(message.data.pack('C*'))).read : message.data
      data = JSON.parse(message, symbolize_names: true)
      methods[:log]&.call("Got message: #{data}")
      #             successfully subscribed
      return if data[:status] == 'ok' && data[:subbed]

      #          successfully autheticated
      if data[:ch] == 'auth' && data[:code] == 200
        send_to_websocket(req_type: @req_type, params: @params)
        return
      end

      #  v1 ping                v2 ping(auth)
      if data[:ping] || (data[:action] && data[:action] == 'ping')
        send_pong(data)
        methods[:ping]&.call(data)
        return
      end

      if (data[:status] == 'error') || (data[:ch] == 'auth' && data[:code] != 200)
        methods[:error].call(data)
      else
        methods[:message].call(data)
      end
    end

    def send_auth
      message = stream_auth_request_data
      @callbacks_hash[:log]&.call("Send auth: #{message}")
      @websocket.send(message)
    end

    def send_pong(data)
      ts = data[:ping]
      message_hash = if ts
                       { pong: ts }
                     else
                       {
                         action: 'pong',
                         data: { ts: data[:data][:ts] }
                       }
                     end
      @callbacks_hash[:log]&.call("Send pong: #{message_hash}")

      @websocket.send(message_hash.to_json)
    end

    def zipped_answer?(topic)
      TOPICS[topic][:zipped_answer]
    end

    def auth_required?(topic)
      TOPICS[topic][:auth_required]
    end

    def signature(timestamp)
      str = AUTH_SIGNATURE_STR.dup
      timestamp = timestamp.gsub(':', '%3A')
      subst_hash = { access_key: @access_key, timestamp: timestamp }
      str = substitude(str: str, subst_hash: subst_hash)
      Base64.encode64(OpenSSL::HMAC.digest('sha256', @secret.to_s, str)).strip
    end

    def substitude(str:, subst_hash:)
      subst_hash.each_pair { |k, v| str.gsub!("$#{k}$", v.to_s) }
      str
    end

  end
end
