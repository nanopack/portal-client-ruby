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
    request :get, '/services'
  end

  # Fetch information about a particular service
  def service(id)
    request :get, "/services/#{id}"
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
    request :post, '/services', service
  end

  # Reset the entire list of services.
  #
  # services: A list of services following the structure above.
  def reset_services(services=[])
    request :put, '/services', services
  end

  # Remove a service
  def remove_service(id)
    request :delete, "/services/#{id}"
  end

  # List the servers for a registered service
  def servers(service_id)
    request :get, "/services/#{service_id}/servers"
  end

  # Fetch a single service for a registered service
  def server(service_id, server_id)
    request :get, "/services/#{service_id}/servers/#{server_id}"
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
    request :post, "/services/#{service_id}/servers"
  end

  # Reset the list of servers registered to a service
  #
  # servers: A list of servers following the data above
  def reset_servers(service_id, servers=[])
    request :put, "/services/#{service_id}/servers"
  end

  # Remove a server from a registered service
  def remove_server(service_id, server_id)
    request :delete, "/services/#{service_id}/servers/#{server_id}"
  end

  # List the installed SSL certs
  def certs
    request :get, '/certs'
  end

  # Register an SSL cert with the http router
  #
  # cert:
  #   cert: Certificate cert as a raw string (unencoded)
  #   key: Certificate key as a raw string (unencoded)
  def register_cert(cert)
    request :post, '/certs', cert
  end

  # Reset the registered certs
  #
  # certs: A list of certs, following the data above
  def reset_certs(certs=[])
    request :put, '/certs', certs
  end

  # Remove a cert from the router
  #
  # cert: Follows the format above
  def remove_cert(cert={})
    request :delete, '/certs', cert
  end

  # List the registered http routes
  def routes
    request :get, '/routes'
  end

  # Register a new route to the http router
  #
  # route:
  #   subdomain: Subdomain of the request. Optional. Assumes *
  #   domain: Domain of the request. Optional. Assumes *
  #   path: Path of the incoming request
  #   targets: List of locations to forward the request
  #   fwdpath: Path to forward to targets (combined with target path)
  #   page: A page to render when Name and Path match (optional)
  def add_route(route={})
    request :post, '/routes', route
  end

  # Reset the registered routes
  #
  # routes: A list of routes, following the data above
  def reset_routes(routes=[])
    request :put, '/routes', routes
  end

  # Remove a route from the router
  #
  # route: Follows the format above
  def remove_route(route={})
    request :delete, '/routes', route
  end

  # List the registered vips
  # $ curl -k -H "X-AUTH-TOKEN:" https://127.0.0.1:8443/vips
  # []
  def vips
    request :get, '/vips'
  end

  # Register a new vip with the http router
  # $ curl -k -H "X-AUTH-TOKEN:" https://127.0.0.1:8443/vips \
  #      -d '{"ip":"192.168.0.100","interface":"eth0","alias":"eth0:1"}'
  # [{"ip":"192.168.0.100","interface":"eth0","alias":"eth0:1"}]
  def add_vip(vip={})
    request :post, '/vips', vip
  end

  # Reset the registered vips
  #
  # vips: A list of vips, following the data above
  # $ curl -k -H "X-AUTH-TOKEN:" https://127.0.0.1:8443/vips \
  #      -d [{"ip":"192.168.0.100","interface":"eth0","alias":"eth0:1"}]
  #      -X PUT
  # [{"ip":"192.168.0.100","interface":"eth0","alias":"eth0:1"}]
  def reset_vips(vips=[])
    request :put, '/vips', vips
  end

  # Remove a vip from the router
  #
  # vip: Follows the format above
  # $ curl -k -H "X-AUTH-TOKEN:" https://127.0.0.1:8443/vips \
  #      -d '{"ip":"192.168.0.100","interface":"eth0"}'
  #      -X DELETE
  # {"msg":"Success"}
  def remove_vip(vip={})
    request :delete, '/vips', vip
  end

  protected

  def request(method, path, payload = {})
    res = connection.send(method, path) do |req|
      req.headers['X-AUTH-TOKEN'] = token
      req.body = to_json(payload)
    end

    process_response(res)
  rescue Faraday::ClientError => e
    raise ::Portal::ConnectionError, e.message
  end

  def process_response(res)
    status_body = "#{res.status}:#{res.body}"

    if res.status >= 200 && res.status < 300
      from_json(res.body)
    elsif res.status >= 300 && res.status < 400
      raise ::Portal::RedirectionError, status_body
    elsif res.status == 401
      raise ::Portal::UnauthorizedError, status_body
    elsif res.status == 404
      raise ::Portal::NotFoundError, status_body
    elsif res.status >= 400 && res.status < 500
      # e.g. 400:{"error":"Port Already In Use"}
      raise ::Portal::ClientError, status_body
    elsif res.status >= 500
      raise ::Portal::ServerError, status_body
    else
      # This should be an edge-case. All known statuses should be handled.
      fail status_body
    end
  end

  def connection
    @connection ||= ::Faraday.new({
      url: url,
      :ssl => {:verify => false}
    })
  end

  def url
    if host =~ /:\d+/
      "https://#{host}"
    else
      "https://#{host}:8443"
    end
  end

  def to_json(data)
    JSON.dump(data)
  end

  def from_json(data)
    JSON.parse(data)
  end
end
