class Rack::Attack
  # Throttle login attempts for a given IP address to 5 requests per minute
  throttle('logins/ip', limit: 5, period: 60.seconds) do |req|
    if req.path == '/users/sign_in' && req.post?
      req.ip
    end
  end
end

Rails.application.config.middleware.use Rack::Attack
