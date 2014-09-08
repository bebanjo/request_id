begin
  require 'sidekiq/middleware/server/logging'
rescue LoadError
  # No sidekiq
end

module Sidekiq
  module Middleware
    module Server
      class RequestId < Logging
        class << self
          attr_accessor :no_reset
        end

        def call(worker, item, queue)
          request_id = ::RequestId.request_id = item['request_id']
          Sidekiq::Logging.with_context("request_id=#{request_id} worker=#{worker.class.to_s} jid=#{item['jid']} args=#{item['args'].inspect}") do
            begin
              start = Time.now
              logger.info { "at=start" }
              yield
              logger.info { "at=done duration=#{elapsed(start)}sec" }
            rescue Exception
              logger.info { "at=fail duration=#{elapsed(start)}sec" }
              raise
            end
          end
        ensure
          ::RequestId.request_id = nil unless self.class.no_reset
        end

      end
    end
  end
end
