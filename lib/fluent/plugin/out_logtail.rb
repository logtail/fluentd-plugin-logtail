require 'fluent/output'

module Fluent
  class LogtailOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('logtail', self)

    VERSION = "0.1.0".freeze
    CONTENT_TYPE = "application/msgpack".freeze
    HOST = "https://in.logtail.com".freeze
    PATH = "/".freeze
    MAX_ATTEMPTS = 3.freeze
    RETRYABLE_CODES = [429, 500, 502, 503, 504].freeze
    USER_AGENT = "Logtail Logstash/#{VERSION}".freeze

    config_param :source_token, :string, secret: true
    config_param :ip, :string, default: nil

    def configure(conf)
      source_token = conf["source_token"]
      @headers = {
        "Authorization" => "Bearer #{source_token}",
        "Content-Type" => CONTENT_TYPE,
        "User-Agent" => USER_AGENT
      }
      super
    end

    def start
      super
      require 'http'
      HTTP.default_options = {:keep_alive_timeout => 29}
      @http_client = HTTP.persistent(HOST)
    end

    def shutdown
      @http_client.close if @http_client
      super
    end

    def format(tag, time, record)
      record.merge("dt" => Time.at(time).utc.iso8601).to_msgpack
    end

    def write(chunk)
      deliver(chunk, 1)
    end

    private
      def deliver(chunk, attempt)
        if attempt > MAX_ATTEMPTS
          log.error("msg=\"Max attempts exceeded dropping chunk\" attempt=#{attempt}")
          return false
        end

        body = chunk.read
        response = @http_client.headers(@headers).post(PATH, body: body)
        response.flush
        code = response.code

        if code >= 200 && code <= 299
          true
        elsif RETRYABLE_CODES.include?(code)
          sleep_time = sleep_for_attempt(attempt)
          log.warn("msg=\"Retryable response from the Logtail API\" " +
            "code=#{code} attempt=#{attempt} sleep=#{sleep_time}")
          sleep(sleep_time)
          deliver(chunk, attempt + 1)
        else
          log.error("msg=\"Fatal response from the Logtail API\" code=#{code} attempt=#{attempt}")
          false
        end
      end

      def sleep_for_attempt(attempt)
        sleep_for = attempt ** 2
        sleep_for = sleep_for <= 60 ? sleep_for : 60
        (sleep_for / 2) + (rand(0..sleep_for) / 2)
      end
  end
end
