SecureHeaders::Configuration.default do |config|
  config.cookies = {
    secure: true, # segnala al browser di usare solo HTTPS
    httponly: true, # impedisce l'accesso ai cookie via JavaScript
  }
  config.hsts = "max-age=#{1.year.to_i}; includeSubdomains" # forza l'uso di HTTPS
  config.x_frame_options = "DENY" # impedisce l'uso del sito in un iframe
  config.x_content_type_options = "nosniff" # impedisce l'inferenza del tipo di contenuto
  config.x_xss_protection = "1; mode=block" # abilita la protezione XSS
  config.x_download_options = "noopen"
  config.x_permitted_cross_domain_policies = "none"
  config.referrer_policy = "strict-origin-when-cross-origin"
  config.csp = {
    default_src: ["'self'"],
    script_src: ["'self'", "https://trusted.cdn.com"],
    style_src: ["'self'", "https://trusted.cdn.com"],
    img_src: ["'self'", "data:", "https://trusted.cdn.com"],
    object_src: ["'none'"],
    frame_ancestors: ["'none'"],
    base_uri: ["'self'"],
    form_action: ["'self'"]
  }
end
