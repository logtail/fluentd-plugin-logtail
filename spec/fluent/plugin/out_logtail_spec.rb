require "spec_helper"
require "fluent/plugin/out_logtail"

describe Fluent::LogtailOutput do
  let(:config) do
    %{
      source_token  abcd1234
    }
  end

  let(:cloud_config) do
    %{
      source_token  abcd1234
      ingesting_host s1234.eu-nbg-2.betterstackdata.com
    }
  end

  let(:driver) do
    tag = "test"
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::LogtailOutput, tag) {
      # v0.12's test driver assume format definition. This simulates ObjectBufferedOutput format
      if !defined?(Fluent::Plugin::Output)
        def format(tag, time, record)
          [time, record].to_msgpack
        end
      end
    }.configure(config)
  end

  let(:cloud_driver) do
    tag = "test"
    Fluent::Test::BufferedOutputTestDriver.new(Fluent::LogtailOutput, tag) {
      # v0.12's test driver assume format definition. This simulates ObjectBufferedOutput format
      if !defined?(Fluent::Plugin::Output)
        def format(tag, time, record)
          [time, record].to_msgpack
        end
      end
    }.configure(cloud_config)
  end

  let(:record) do
    {'age' => 26, 'request_id' => '42', 'parent_id' => 'parent', 'routing_id' => 'routing'}
  end

  before(:each) do
    Fluent::Test.setup
  end

  describe "#write" do
    it "should send a chunked request to the Logtail API using default host" do
      stub = stub_request(:post, "https://in.logs.betterstack.com/").
        with(
          :body => start_with("\xDD\x00\x00\x00\x01\x85\xA3age\x1A\xAArequest_id\xA242\xA9parent_id\xA6parent\xAArouting_id\xA7routing\xA2dt\xB4".force_encoding("ASCII-8BIT")),
          :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer abcd1234', 'Content-Type'=>'application/msgpack', 'User-Agent'=>'Logtail Fluentd/0.1.1'}
        ).
        to_return(:status => 202, :body => "", :headers => {})

      driver.emit(record)
      driver.run

      expect(stub).to have_been_requested.times(1)
    end

    it "handles 500s" do
      stub = stub_request(:post, "https://in.logs.betterstack.com/").to_return(:status => 500, :body => "", :headers => {})

      driver.emit(record)
      driver.run

      expect(stub).to have_been_requested.times(3)
    end

    it "handle auth failures" do
      stub = stub_request(:post, "https://in.logs.betterstack.com/").to_return(:status => 403, :body => "", :headers => {})

      driver.emit(record)
      driver.run

      expect(stub).to have_been_requested.times(1)
    end
  end

  describe "#write to cloud" do
    it "should send a chunked request to the Logtail API" do
      stub = stub_request(:post, "https://s1234.eu-nbg-2.betterstackdata.com/").
        with(
          :body => start_with("\xDD\x00\x00\x00\x01\x85\xA3age\x1A\xAArequest_id\xA242\xA9parent_id\xA6parent\xAArouting_id\xA7routing\xA2dt\xB4".force_encoding("ASCII-8BIT")),
          :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'Authorization'=>'Bearer abcd1234', 'Content-Type'=>'application/msgpack', 'User-Agent'=>'Logtail Fluentd/0.1.1'}
        ).
        to_return(:status => 202, :body => "", :headers => {})

      cloud_driver.emit(record)
      cloud_driver.run

      expect(stub).to have_been_requested.times(1)
    end
  end
end