# coding: utf-8
require "awesome_print"
require 'huobi_client/request'
require 'active_support/all'

module HuobiClient
  class Client
    attr_reader :access, :secret, :account_id

    include HuobiClient::Request

    def initialize(access, secret, account_id=nil)
      @access = access
      @secret = secret
      @account_id = account_id
    end

    # API key query
    # This endpoint is used by the parent user to query their own API key information, and the parent user to query their sub user's API key information

    def api_key
      get '/v2/user/api-key'
    end

    # Get UID
    # This endpoint allow users to view the user ID of the account easily

    def uid
      get '/v2/user/uid'
    end

    # Get Klines (Candles)
    # This endpoint retrieves all klines in a specific range
    #
    # symbol: string - The trading symbol to query	All trading symbol supported, e.g. btcusdt, bccbtcn (to retrieve candlesticks for ETP NAV, symbol = ETP trading symbol + suffix 'nav'，for example: btc3lusdtnav)
    # period: string - The period of each candle	1min, 5min, 15min, 30min, 60min, 4hour, 1day, 1mon, 1week, 1year
    # size:	integer - The number of data returns [1-2000]

    def kline(symbol:, period:, size: 150)
      get '/market/history/kline', fun_params(__method__, binding)
    end

    # Get Latest Aggregated Ticker
    # This endpoint retrieves the latest ticker with some important 24h aggregated market data.
    #
    # symbol:	string - The trading symbol to query	All supported trading symbol, e.g. btcusdt, bccbtc.Refer to /v1/common/symbols

    def ticker(symbol:)
      get '/market/detail/merged', fun_params(__method__, binding)
    end

    # Get Market Depth
    # This endpoint retrieves the current order book of a specific pair.
    #
    # symbol: string	The trading symbol to query	Refer to GET /v1/common/symbols
    # depth: integer	The number of market depth to return on each side	5, 10, 20 (default: 20)
    # type: string	Market depth aggregation level, details below	step0, step1, step2, step3, step4, step5 (default: step0)
    # * when type is set to "step0", the default value of "depth" is 150 instead of 20.

    def depth(symbol:, type: nil, depth: nil)
      get '/market/depth', fun_params(__method__, binding)
    end

    # Get the Last Trade
    # This endpoint retrieves the latest trade with its price, volume, and direction.
    #
    # symbol:	string	- The trading symbol to query. Refer to GET /v1/common/symbols

    def trade_detail(symbol:)
      get '/market/trade', fun_params(__method__, binding)
    end

    def trade_list(symbol:, size: 1)
      get '/market/history/trade', fun_params(__method__, binding)
    end

    def market_detail(symbol:)
      get '/market/detail', fun_params(__method__, binding)
    end

    # 公共API
    def symbols
      get '/v1/common/symbols'
    end

    def market_status
      get '/v2/market-status'
    end

    def hadax_symbols
      get '/v1/hadax/common/symbols'
    end

    def currencys
      get '/v1/common/currencys'
    end

    def currencies
      get '/v2/reference/currencies'
    end

    def currencies_details
      get '/v2/settings/common/currencies'
    end

    def hadax_currencys
      get '/v1/hadax/common/currencys'
    end

    def timestamp
      get '/v1/common/timestamp'
    end

    # 用户资产API
    def accounts
      get '/v1/account/accounts'
    end

    def balance(account_id: @account_id)
      get "/v1/account/accounts/#{account_id}/balance"
    end

    def hadax_balance(account_id: @account_id)
      get "/v1/hadax/account/accounts/#{account_id}/balance"
    end

    # Place a New Order
    #
    # params:
    # account-id: The account id used for this trade
    # symbol: The trading symbol to trade
    # type: The order type
    # amount: order size (for buy market order, it's order value)
    # price: The order price (not available for market order)
    # source: When trade with spot use 'spot-api';When trade with isolated margin use 'margin-api'; When trade with cross margin use 'super-margin-api';When trade with c2c-margin use 'c2c-margin-api';
    # client-order-id: Client order ID (maximum 64-character length, to be unique within 8 hours)
    # stop-price: Trigger price of stop limit order
    # operator: operation character of stop price: gte – greater than and equal (>=), lte – less than and equal (<=)
    #
    # types:
    # buy-market / sell-market
    # buy-limit /sell-limit
    # buy-ioc / sell-ioc
    # buy-limit-maker / sell-limit-maker
    # buy-stop-limit / sell-stop-limit
    # buy-limit-fok / sell-limit-fok
    # buy-stop-limit-fok / sell-stop-limit-fok

    def place(account_id: @account_id, symbol:, type:, amount:, price: nil, source: 'api', client_order_id: nil,
              stop_price: nil, operator: nil)
      post '/v1/order/orders/place', fun_params(__method__, binding)
    end

    # Get All Open Orders
    #
    # This endpoint returns all open orders which have not been filled completely.

    def open_orders
      get '/v1/order/openOrders'
    end

    def hadax_place(account_id: @account_id, symbol:, type:, amount:, price: nil, source: 'api') # HADAX站下单
      post '/v1/hadax/order/orders/place', fun_params(__method__, binding)
    end

    # Submit Cancel for an Order
    #
    # This endpoint submits a request to cancel an order.
    #
    # order-id:	string - order id which needs to be filled in the path
    # symbol:	string - symbol which needs to be filled in the URL
    #
    # * The actual result of the cancellation request needs to be checked by order status or match result endpoints after submitting the request.

    def submit_cancel(order_id:, symbol: nil)
      post "/v1/order/orders/#{order_id}/submitcancel"
    end

    # Submit Cancel for an Order (based on client order ID)
    #
    # This endpoint submit a request to cancel an order based on client-order-id .
    #
    # * It is suggested to use submit_cancel to cancel a single order, which is faster and more stable
    # * This only submits the cancel request, the actual result of the canel request needs to be checked by order status or match result endpoints

    def submit_cancel_cid(client_order_id:, symbol: nil)
      post "/v1/order/orders/submitCancelClientOrder", fun_params(__method__, binding)
    end

    def batch_cancel(order_ids:) # 批量撤销订单
      post '/v1/order/orders/batchcancel', fun_params(__method__, binding)
    end

    def order_detail(order_id:) # 查询某个订单详情
      get "/v1/order/orders/#{order_id}"
    end

    def order_detail_by_cid(clientOrderId:) # 查询某个订单详情
      get "/v1/order/orders/getClientOrder", fun_params(__method__, binding)
    end

    def match_results(order_id:) # 查询某个订单的成交明细
      get "/v1/order/orders/#{order_id}/matchresults"
    end

    def orders(symbol: nil, states:, types: nil, start_date: nil, end_date: nil, from: nil, direct: nil, size: nil) # 查询当前委托、历史委托
      # direct	false	string	查询方向		prev 向前，next 向后
      # states	true	string	查询的订单状态组合，使用','分割		pre-submitted 准备提交, submitted 已提交, partial-filled 部分成交, partial-canceled 部分成交撤销, filled 完全成交, canceled 已撤销
      get '/v1/order/orders', fun_params(__method__, binding)
    end

    def all_match_results(symbol: nil, types: nil, start_time: nil, end_time: nil, from: nil, direct: nil, size: nil) # 查询当前成交、历史成交
      get '/v1/order/matchresults', fun_params(__method__, binding)
    end

    # This endpoint returns orders based on a specific searching criteria. The orders created via API will no longer be queryable after being cancelled for more than 2 hours.
    def order_history(symbol: nil, start_time: nil, end_time: nil, direct: nil, size: nil)
      # direct	    false	string	Direction of the query	| prev, next (default: next)
      # start-time	false	long	  Start time (included) | UTC time in millisecond (default: 48 hours)
      # end-time	  false	long	  End time (included) | 	UTC time in millisecond (default: The query time)
      # size	      false	int	    Number of items in each response (10-1000, default: 100)
      get '/v1/order/history', fun_params(__method__, binding)
    end

    # 借贷交易API （重要：如果使用借贷资产交易，请在下单接口/v1/order/orders/place请求参数source中填写‘margin-api’）

    def dw_transfer_in(symbol:, currency:, amount:) # 现货账户划入至借贷账户
      post '/v1/dw/transfer-in/margin', fun_params(__method__, binding)
    end

    def dw_transfer_out(symbol:, currency:, amount:) # 借贷账户划出至现货账户
      post '/v1/dw/transfer-out/margin', fun_params(__method__, binding)
    end

    def margin_apply(symbol:, currency:, amount:) # 申请借贷
      post '/v1/margin/orders', fun_params(__method__, binding)
    end

    def margin_repay(amount:, order_id:) # 归还借贷
      post "/v1/margin/orders/#{order_id}/repay", fun_params(__method__, binding)
    end

    def loan_orders(symbol:, states: nil, start_date: nil, end_date: nil, from: nil, direct: nil, size: nil) # 借贷订单
      get '/v1/margin/loan-orders', fun_params(__method__, binding)
    end

    def margin_balance(symbol:) # 借贷账户详情
      get '/v1/margin/accounts/balance', fun_params(__method__, binding)
    end

    # 虚拟币提现API
    def withdraw(address:, amount:, currency:, fee: nil, addr_tag: nil, chain: nil, client_order_id: nil) # 申请提现虚拟币
      post '/v1/dw/withdraw/api/create', fun_params(__method__, binding)
    end

    def withdraw_cancel(withdraw_id:) # 申请取消提现虚拟币
      post "/v1/dw/withdraw-virtual/#{withdraw_id}/cancel"
    end

    def withdraw_detail_by_cid(clientOrderId:)
      get "/v1/query/withdraw/client-order-id", fun_params(__method__, binding)
    end

    def withdraw_query(currency: nil, type:, from: nil, size: nil, direct: 'next') # 查询虚拟币充提记录
      # type: 'deposit' or 'withdraw'
      get '/v1/query/deposit-withdraw', fun_params(__method__, binding)
    end

    def withdraw_quota(currency:)
      get '/v2/account/withdraw/quota', fun_params(__method__, binding)
    end

    def deposit_address(currency:, subUid: nil)
      if subUid
        get '/v2/sub-user/deposit-address', fun_params(__method__, binding)
      else
        get '/v2/account/deposit/address', fun_params(__method__, binding)
      end
    end

    # Get Sub User's List
    def subusers
      get '/v2/sub-user/user-list'
    end

    # Transfer Asset between Parent and Sub Account
    # sub-uid: integer - The sub account's uid to transfer to or from
    # currency: string - The type of currency to transfer
    # amount:	decimal	- The amount of asset to transfer
    # type:	string - The type of transfer	(master-transfer-in, master-transfer-out, master-point-transfer-in, master-point-transfer-out)

    def subuser_transfer(sub_uid:, currency:, amount:, type:)
      post '/v1/subuser/transfer', fun_params(__method__, binding)
    end

    # Get Account Balance of a Sub-User
    def subuser_balance(sub_uid:)
      get "/v1/account/accounts/#{sub_uid}"
    end

    # only for sub-accounts, for main account use withdraw_query method
    def deposit_query(subUid:, currency: nil, startTime: nil, endTime: nil, sort: nil, limit: nil, fromId: nil)
      get '/v2/sub-user/query-deposit', fun_params(__method__, binding)
    end

    private

    def fun_params(_method, _binding)
      Hash[method(_method).parameters.map.collect { |_, name| [name, _binding.local_variable_get(name)] }]
        .transform_keys { |key| key.to_s.gsub('_', '-') }
    end

  end
end
