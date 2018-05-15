# encoding: utf-8

require 'active_support/core_ext/hash/keys'

module HuobiClient
  class Response
    SUCCESS_STATUS = [200, 201, 204]
    attr_reader :original_response, :body, :success

    def initialize(faraday_response)
      @original_response = faraday_response
      @body = faraday_response.body
      @success = false

      begin
        @body = JSON.parse(@body) unless @body.is_a? Hash
        @body = @body.with_indifferent_access if @body.is_a? Hash
      rescue => e
        p e.message
        p e.backtrace.join("\n")
      end

      if SUCCESS_STATUS.include? original_response.status
        @success = @body[:status] == 'ok'
      end
    end

    def success?
      @success
    end

    def headers
      original_response.headers
    end

    def status
      original_response.status
    end
  end
end
