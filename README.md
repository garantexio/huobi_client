# HuobiClient

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/huobi_client`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'huobi_client'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install huobi_client

## Usage

client = HuobiClient.new(access, secret)

.kline
.ticker
.depth
.trade_detail
.trade_list
.market_detail
.
symbols
.hadax_symbols
.currencys
.hadax_currencys
.timestamp

.accounts
.balance
.hadax_balance

.place
.hadax_place
.submit_cancel
.batch_cancel
.order_detail
.match_results
.orders
.all_match_results

.dw_transfer_in
.dw_transfer_out
.margin_apply
.margin_repay
.loan_orders
.margin_balance

.withdraw
.withdraw_cancel
.withdraw_query

[中文](https://github.com/huobiapi/API_Docs/wiki/REST_authentication)
[English](https://github.com/huobiapi/API_Docs_en/wiki/REST_Reference)


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/huobi_client.
