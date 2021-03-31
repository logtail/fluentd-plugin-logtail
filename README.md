# 🪵 Fluent::Plugin::Logtail, a plugin for [Fluentd](http://fluentd.org)

[![build](https://github.com/logtail/fluentd-plugin-logtail/actions/workflows/main.yml/badge.svg)](https://github.com/logtail/fluentd-plugin-logtail/actions/workflows/main.yml)

A Fluentd plugin that delivers events to the [Logtail.com logging service](https://logtail.com). It uses batching, msgpack, and retry logic for highly efficient and reliable delivery of log data.

## Installation

```
gem install fluent-plugin-logtail
```

## Usage

In your Fluentd configuration, use `@type logtail`:

```
<match your_match>
  @type logtail
  source_token YOUR_SOURCE_TOKEN
  # ip 127.0.0.1
  buffer_chunk_limit 1m                      # Must be < 5m
  flush_at_shutdown true                     # Only needed with file buffer
</match>
```

## Configuration

* `source_token` - This is your [Logtail source token](https://logtail.com).

For advanced configuration options, please see to the [buffered output parameters documentation.](http://docs.fluentd.org/articles/output-plugin-overview#buffered-output-parameters).
