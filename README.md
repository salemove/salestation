# Salestation

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

### Using a logger

Salestation provides a rack logging middleware which can be used to log structured objects.

```ruby
class Webapp < Sinatra::Base
  # ...
  use Salestation::Web::RequestLogger, my_logger
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/salestation.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

