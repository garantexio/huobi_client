# -*- coding: utf-8 -*-

require 'logger'

module HuobiClient
  module Log
    class << self
      attr_accessor :logger

      def logger
        @logger ||= Logger.new(STDERR)
      end
    end
  end # module Log
end
