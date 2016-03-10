# portal

A Ruby client for interacting with the [portal](https://github.com/nanopack/portal) service.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'portal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install portal

## Usage

#### Client

Instantiate a client, providing the IP of the host and the security token:
```ruby

client = Portal::Client.new('127.0.0.1', 'secret')

```

#### Services

List registered services:
```ruby
client.services
```

Fetch a single service:
```ruby
client.service(id)
```

Add a new service:
```ruby
client.add_service({
  host: '127.0.0.1',  # IP of the host the service is bound to
  port: 80,           # Port that the service listens to
  type: 'tcp',        # Type of service. Either tcp or udp
  scheduler: 'lc'     # Forwarding algorithm (rr, wrr, lc, wlc, lblc, lblcr, dh, sh, sed, nq)
  persistence: 300,   # Timeout for keeping requests from the same client going to the same server
  netmask: ''         # How to group clients with persistence to servers
})
```

Remove a service:
```ruby
client.remove_service(id)
```

#### Servers (service targets)

List servers for a registered service
```ruby
client.servers(service_id)
```

Fetch a single server from a registered service
```ruby
client.server(service_id, server_id)
```

Add a server to a registered service
```ruby
client.add_server(service_id, {
  host: '127.0.0.1',      # IP of the host the service is bound to.
  port: 80,               # Port that the service listens to.
  forwarder: 'm',         # Method to use to forward traffic to this server. One of the following: g (gatewaying), i (ipip), m (masquerading)
  weight: 1,              # Weight to perfer this server. Set to 0 if no traffic should go to this server.
  upper_threshold: 0,     # Stop sending connections to this server when this number is reached. 0 is no limit.
  lower_threshold: 0      # Restart sending connections when drains down to this number. 0 is not set.
})
```

Reset the servers of a registered service
```ruby
client.reset_servers(service_id, [
  # server objects as defined above
])
```

Remove server:
```ruby
client.remove_server(service_id, server_id)
```

#### HTTP Routing

List the registered routes:

```ruby
client.routes
```

Register a new route:

```ruby
client.add_route({
    subdomain: 'blog',              # Subdomain of the request. Optional. Assumes *
    domain: 'nanobox.io',           # Domain of the request. Optional. Assumes *
    path: '/',                      # Path of the incoming request
    targets: ['http://192.168.0.2'] # List of locations to forward the request
    page: 'hello world'             # A page to render when Name and Path match (optional)
})
```

Reset routes:

```ruby
client.reset_routes([
    # Routes entered as example above
])
```

Remove route:

```ruby
client.remove_route({
    # Route entered as example above
})
```

#### TLS/SSL certs

List installed certs:

```ruby
client.certs
```

Register a cert with the router:

```ruby
client.register_cert({
    cert: 'abcd3...',   # Certificate cert as a raw string (unencoded)
    key: 'abcd3...'     # Certificate key as a raw string (unencoded)
})
```

Reset the registered certs:

```ruby
client.reset_certs([
    # Certs entered as example above
])
```

Remove a cert:

```ruby
client.remove_cert({
    # Cert entered as example above
})
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/nanopack/portal.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
