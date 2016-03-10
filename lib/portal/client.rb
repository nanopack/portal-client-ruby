require 'faraday'
require 'json'

class Portal::Client

  attr_reader :host
  attr_reader :token

  def initialize(host='127.0.0.1', token='123')
    @host  = host
    @token = token
  end

  # List registered services
  def services
    get '/services'
  end

  # Fetch information about a particular service
  def service(id)
    get "/services/#{id}"
  end

  # Add a service
  #
  # service:
  #   host: IP of the host the service is bound to
  #   port: Port that the service listens to
  #   type: Type of service. Either tcp or udp
  #   scheduler: Forwarding algorithm (rr, wrr, lc, wlc, lblc, lblcr, dh, sh, sed, nq)
  #   persistence: Timeout for keeping requests from the same client going to the same server
  #   netmask: How to group clients with persistence to servers
  #   servers: Array of server objects associated to the service (optional)
  def add_service(service={})
    post '/services', service
  end

  # Remove a service
  def remove_service(id)
    delete "/services/#{id}"
  end

  # List the servers for a registered service
  def servers(service_id)
    get "/services/#{service_id}/servers"
  end

  # Fetch a single service for a registered service
  def server(service_id, server_id)
    get "/services/#{service_id}/servers/#{server_id}"
  end

  # Add a server to a service
  #
  # service
  #   host: IP of the host the service is bound to.
  #   port: Port that the service listens to.
  #   forwarder: Method to use to forward traffic to this server.
  #     One of the following: g (gatewaying), i (ipip), m (masquerading)
  #   weight: Weight to perfer this server. Set to 0 if no traffic should go to this server.
  #   upper_threshold: Stop sending connections to this server when this number is reached. 0 is no limit.
  #   lower_threshold: Restart sending connections when drains down to this number. 0 is not set.
  def add_server(service_id, server={})
    post "/services/#{service_id}/servers"
  end

  # Reset the list of servers registered to a service
  #
  # servers: A list of servers following the data above
  def reset_servers(service_id, servers=[])
    put "/services/#{service_id}/servers"
  end

  # Remove a server from a registered service
  def remove_server(service_id, server_id)
    delete "/services/#{service_id}/servers/#{server_id}"
  end

  # List the installed SSL certs
  def certs
    get '/certs'
  end

  # Register an SSL cert with the http router
  #
  # cert:
  #   cert: Certificate cert as a raw string (unencoded)
  #   key: Certificate key as a raw string (unencoded)
  def register_cert(cert)
    post '/certs', cert
  end

  # Reset the registered certs
  #
  # certs: A list of certs, following the data above
  def reset_certs(certs=[])
    put '/certs', certs
  end

  # Remove a cert from the router
  #
  # cert: Follows the format above
  def remove_cert(cert={})
    delete '/certs', cert
  end

  # List the registered http routes
  def routes
    get '/routes'
  end

  # Register a new route to the http router
  #
  # route:
  #   subdomain: Subdomain of the request. Optional. Assumes *
  #   domain: Domain of the request. Optional. Assumes *
  #   path: Path of the incoming request
  #   targets: List of locations to forward the request
  #   page: A page to render when Name and Path match (optional)
  def add_route(route={})
    post '/routes', route
  end

  # Reset the registered routes
  #
  # routes: A list of routes, following the data above
  def reset_routes(routes=[])
    put '/routes', routes
  end

  # Remove a route from the router
  #
  # route: Follows the format above
  def remove_route(route={})
    delete '/routes', route
  end

  protected

  def get(path)
    res = connection.get(path) do |req|
      req.headers['X-TOKEN'] = token
    end

    if res.status == 200
      from_json(res.body) rescue ""
    else
      raise "#{res.status}:#{res.body}"
    end
  end

  def post(path, payload)
    res = connection.post(path) do |req|
      req.headers['X-TOKEN'] = token
      req.body = to_json(payload)
    end

    if res.status == 200
      from_json(res.body) rescue ""
    else
      raise "#{res.status}:#{res.body}"
    end
  end

  def put(path, payload)
    res = connection.put(path) do |req|
      req.headers['X-TOKEN'] = token
      req.body = to_json(payload)
    end

    if res.status == 200
      from_json(res.body) rescue ""
    else
      raise "#{res.status}:#{res.body}"
    end
  end

  def delete(path, payload={})
    res = connection.delete(path) do |req|
      req.headers['X-TOKEN'] = token
      if payload
        req.body = to_json(payload)
      end
    end

    if res.status == 200
      true
    else
      raise "#{res.status}:#{res.body}"
    end
  end

  def connection
    @connection ||= ::Faraday.new({
      url: "https://#{host}:8443",
      :ssl => {:verify => false}
    })
  end

  def to_json(data)
    JSON.dump(data)
  end

  def from_json(data)
    JSON.parse(data)
  end

end
