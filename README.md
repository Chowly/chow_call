# Chow::Call

Forked from the unmaintained "[We::Call](https://github.com/wework/we-call-gem)"

[![Build Status][ci-image]][ci-url]
[![Coverage Status][coveralls-image]][coveralls-url]
[![MIT License][license-image]][license-url]

![Call me Maybe](https://cloud.githubusercontent.com/assets/67381/25590846/0c3145ea-2e80-11e7-9166-76448e0134a8.jpeg)

Requires metadata and offers client/server middleware to help debug HTTP calls, raise warnings for deprecations, supporting trace IDs, etc.

It aims to arm API developers and users with tools to make their calls more robust, and enforces Good Ideas™ with sane defaults whenever possible.

## Goals

- Work just like Faraday out of the box
- Remove some of the guesswork that comes with HTTP service orientated architecures
- Provide sane defaults whenever possible, but ask for more information if required
- Facilitate [HTTP Evolution](https://www.mnot.net/blog/2012/12/04/api-evolution.html)

## Usage


```ruby
gem 'chow-call'
```

```ruby
# config/initializers/chow-call.rb

Chow::Call.configure do |config|
  config.app_name = 'service-a'       # default nil (Connection class falls back to APP_NAME or Rails name)
  config.app_env = 'staging'          # default nil (Connection class back to RACK_ENV || RAILS_ENV)
  config.detect_deprecations = false  # default true
end
```

As this is a Faraday wrapper, the only thing that will change from normal Faraday usage is initialization.

```ruby
connection = Chow::Call::Connection.new(host: 'https://some-service.example.com/', timeout: 2)

# or with a Faraday connection block
connection = Chow::Call::Connection.new(host: 'https://some-service.example.com/', timeout: 2) do |conn|
  conn.token_auth('abc123token')
  conn.headers['Foo'] = 'bar'
end
```

See more connection block options in the [Faraday documentation](https://github.com/lostisland/faraday).

### Provide an App

An application should provide its own name in the user agent when calling other services. This is important in case this app busts a local cache, causing it to stampeding herd other service(s).

Other services need to know which server is causing the problem, so no connections are allowed through `Chow::Call` without an app being set.

```ruby
# Provided at config
connection = Chow::Call.configure do |config|
  config.app_name = 'Service A'
end

# Provided at initialization
connection = Chow::Call::Connection.new(host: 'https://service-b.example.com/', app: 'Service A', timeout: 2)
```

_Ofc services could lie about this, so do not use App Name for any sort of security. For that you need to use tokens assigned to applications. This is essentially just forcing a user agent._

### Provide an Env

```ruby
# Provided at config
connection = Chow::Call.configure do |config|
  config.app_env = 'staging'
end

# Provided at initialization
connection = Chow::Call::Connection.new(host: 'https://service-b.example.com/', env: 'staging', timeout: 2)
```

Not only is knowing the app name important, but knowing the env is necessary too. Sometimes people configure stuff wrong, and Service A (staging) will hit Service B (production) 😨.

If you are using Rack or Rails, you should not need to do this, as it'll use RACK_ENV or RAILS_ENV by default.

### Timeouts

By default Faraday will let HTTP calls go on forever. In reality this is often 30 seconds for e.g: a Heroku app. Asking developers to make a choice about how long they're willing to wait on this call gives them a chance to consider an acceptable timeout.

The lower this number can be the better, as it reduces time web threads spend waiting for calls that are unlikely to respond anyway.

```ruby
# Provided at initialization
connection = Chow::Call::Connection.new(host: 'https://service-b.example.com/', timeout: 2)
```

Timeouts can only be provided at initialization of a connection, as they should be different for each service. This is down to the sad reality that some internal services are more performant than others, and various third-parties will have different SLAs.

As well as `timeout: num_seconds` which can set the entire open/read (essentially the total response time of the server), another optional argument exists for `open_timeout: numseconds`. This is how long Chow::Call should spend waiting for a vague sign of life from the server, which by default is 1.


## Middleware

### Client

**Retry**

Automatically enabled, the retry middleware will retry the request in case of network errors. By default, the middleware will retry up to 3 times, waiting 1 second between the retries.

Disable the middleware:

```ruby
Chow::Call.configure do |config|
  config.retry = false
end

# Provided at initialization
connection = Chow::Call::Connection.new(retry_options: false)
```

Adjust the middleware:

```ruby
Chow::Call.configure do |config|
  config.retry_options = { interval: 0.5 }
end

# Provided at initialization
connection = Chow::Call::Connection.new(retry_options: { interval: 0.5 })
```

The gem smartly merges the options passed, so you can specify your own list of exceptions without being afraid to override the default ones:

```ruby
Chow::Call.configure do |config|
  config.retry_options = { exceptions: [Faraday::ResourceNotFound] }
end
```

Check [Faraday's Retry Docs](https://github.com/lostisland/faraday/blob/master/docs/middleware/request/retry.md) for a list of available options.

**DetectDeprecations**

Automatically enabled, the faraday-sunset middleware will watch for the [Sunset header](https://tools.ietf.org/html/draft-wilde-sunset-header-03) and send warning to `ActiveSupport::Deprecation` if enabled, or to whatever is in `ENV['rake.logger']`.

[faraday-sunset]: https://github.com/wework/faraday-sunset

### Server

**LogUserAgent**

_(Optional)_ Log the User Agent, which might just be browser information (merely kinda handy), or could be an app name, like the one `Chow::Call::Connection` asks you for.

```ruby
config.middleware.insert_after Rails::Rack::Logger, Chow::Call::Middleware::Server::LogUserAgent
```

Easy! Check your logs for `user_agent=service-name; app_name=service-name;` The `app_name` will only show up if this was called by `Chow::Call::Connection` (as this is the only thing setting the `X-App-Name` header.)

## Requirements

- **Ruby:** v2.2 - v3.2
- **Faraday:** ~> 1.5.1

_**Note:** Other versions of Faraday may work, but we can't test against all of them forever._
