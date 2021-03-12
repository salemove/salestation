# Salestation

[![Build Status](https://travis-ci.org/salemove/salestation.svg?branch=master)](https://travis-ci.org/salemove/salestation)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'salestation'
```

And then execute:

    $ bundle

## Usage

### Using Salestation with Sinatra

First include `Salestation::Web`. This will provide a method called `process` to execute a request and Responses module for return codes.
```ruby
class Webapp < Sinatra::Base
  include Salestation::Web.new
end
```

Create Salestation application:
```ruby
  def app
    @_app ||= Salestation::App.new(env: ENVIRONMENT)
  end
```

Define a route
```ruby
post '/hello/:name' do
  process(
    HelloUser.call(app.create_request(
      name: params['name']
    )).map(Responses.to_ok)
  )
end
```

Define chain
```ruby
class HelloUser
  def self.call(request)
    request >> upcase >> format
  end

  def self.upcase
    -> (request) do
      input.with_input(name: input.fetch(:name).upcase)
    end
  end

  def self.format
    -> (request) do
      name = request.input.fetch(:name)
      Deterministic::Result::Success(message: "Hello #{name}")
    end
  end
end
```

### Using custom errors in error mapper

Salestation allows and recommends you to define your own custom errors. This is useful when your app has error classes that are not general enough for the salestation library.

```ruby
  include Salestation::Web.new(errors: {
    CustomError => -> (error) { CustomResponse.new(error) }
  })
```

### Providing custom error fields

If you need to specify additional error fields you can use `from` method.
`from` accepts base error on which the rest of the response is built.
Base error must be a hash or implement `to_h` method.

Example:

```
App::Errors::Conflict.from({details: 'details'}, message: 'message', debug_message: 'debug_message')
```

Response:

```javascript
{
  "details": "details",
  "message": "message",
  "debug_message": "debug_message"
}
```

### Using Extractors

Salestation provides extractors to fetch parameters from the request and pass them to the chain.
Available extractors are `BodyParamExtractor`, `QueryParamExtractor`, `ConstantInput`, `HeadersExtractor`.
Multiple extractors can be merged together. If two or more extractors use the same key, the value will be from the last extractor in the merge chain.

`coercions` can optionally be provided to `BodyParamExtractor` and `QueryParamExtractor`. These can be used to transform the values of the extracted parameters.

Define a route

```ruby
include Salestation::Web.new
include Salestation::Web::Extractors

APP = Salestation::App.new(env: {})

def create_app_request
  -> (input) { App.create_request(input) }
end

post '/hello/:name' do |name|
  extractor = BodyParamExtractor[:age]
    .merge(ConstantInput[name: name])
    .merge(HeadersExtractor[
      'accept' => :accept,
      'content-type' => :content_type,
      'x-my-value' => :my_value
    ])
    .coerce(age: ->(age) { age.to_s })

  validate_input = Salestation::Web::InputValidator[
    accept: Salestation::Web::InputValidators::AcceptHeader['application/json', 'application/xml'],
    content_type: Salestation::Web::InputValidators::ContentTypeHeader['application/json'],
    my_value: lambda do |my_value|
      if my_value == 'foo'
        Deterministic::Result::Success(nil)
      else
        Deterministic::Result::Failure('invalid value')
      end
    end
  ]

  response = extractor.call(request)
    .map(validate_input)
    .map(create_app_request)
    .map(HelloUser)
    .map(Responses.to_ok)

  process(response)
end
```

### Using a logger

Salestation provides a rack logging middleware which can be used to log structured objects.

```ruby
class Webapp < Sinatra::Base
  # ...
  use Salestation::Web::RequestLogger, my_logger
end
```

### Using StatsD

Salestation provides a StatsD middleware which can be used record request
execution time. A `timing` call with elapsed seconds is made to the provided
StatsD instance with `path`, `method`, `status` and `status_class` tags.

```ruby
class Webapp < Sinatra::Base
  # ...
  use Salestation::Web::StatsdMiddleware,
    Statsd.new(host, port),
    metric: 'my_service.response.time'
end
```

You can configure per-request tags by defining `salestation.statsd.tags` in sinatra `env`:

```ruby
  def my_handler(env)
    env['salestation.statsd.tags'] = ['foo:bar']
    # ...
  end
```

## RSpec helpers


To use Salestation RSpec matchers you first need to include them:

```
require 'salestation/rspec'

RSpec.configure do |config|
  config.include Salestation::RSpec::Matchers
end
```

After that it's possible to match against error results like this:

```
expect(result).to be_failure
  .with_conflict
  .containing(message: 'Oh noes')
```

See lib/salestation/rspec.rb for more examples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/salestation.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

