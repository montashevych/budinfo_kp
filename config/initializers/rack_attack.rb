# frozen_string_literal: true

# Loaded in all environments; middleware is only inserted in production (see config/environments/production.rb).

class Rack::Attack
  throttle("checkouts/ip", limit: 30, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/checkout"
  end

  throttle("contacts/ip", limit: 20, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/contacts"
  end

  self.throttled_responder = lambda do |_request|
    [ 429, { "Content-Type" => "text/plain; charset=utf-8", "Retry-After" => "3600" }, [ "Too many requests.\n" ] ]
  end
end
