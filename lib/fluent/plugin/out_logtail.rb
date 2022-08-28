require 'fluent/output'
require 'net/https'

module Fluent
  class LogtailOutput < Fluent::BufferedOutput
    Fluent::Plugin.register_output('logtail', self)

    VERSION = "0.1.1".freeze
    CONTENT_TYPE = "application/msgpack".freeze
    HOST = "in.logtail.com".freeze
    PORT = 443
    PATH = "/".freeze
    MAX_ATTEMPTS = 3.freeze
    RETRYABLE_CODES = [429, 500, 502, 503, 504].freeze
    USER_AGENT = "Logtail Fluentd/#{VERSION}".freeze

    config_param :source_token, :string, secret: true
    config_param :ip, :string, default: nil

    def configure(conf)
      @source_token = conf["source_token"]
      super
    end

    def format(tag, time, record)
      force_utf8_string_values(record.merge("dt" => Time.at(time).utc.iso8601)).to_msgpack
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

        http = build_http_client
        records=0
        chunk.each do
          records=records+1
        end
        body = [0xdd,records].pack("CN")
        body << chunk.read

        begin
          resp = http.start do |conn|
            req = build_request(body)
            log.debug("sending #{req.body.length} bytes to logtail")
            conn.request(req)
          end
        ensure
          http.finish if http.started?
        end

        code = resp.code.to_i
        if code >= 200 && code <= 299
          log.debug "POST request to logtail was responded to with status code #{code}"
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

      def force_utf8_string_values(data)
        data.transform_values do |val|
          if val.is_a?(Hash)
            force_utf8_string_values(val)
          elsif val.respond_to?(:force_encoding)
            val.force_encoding('UTF-8')
          else
            val
          end
        end
      end

      def build_http_client
        http = Net::HTTP.new(HOST, PORT)
        http.use_ssl = true
        # Verification on Windows fails despite having a valid certificate.
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
        http.read_timeout = 30
        http.ssl_timeout = 10
        http.open_timeout = 10
        http
      end

      def build_request(body)
        path = '/'
        req = Net::HTTP::Post.new(path)
        req["Authorization"] = "Bearer #{@source_token}"
        req["Content-Type"] = CONTENT_TYPE
        req["User-Agent"] = USER_AGENT
        req.body = body
        req
      end
  end
end
