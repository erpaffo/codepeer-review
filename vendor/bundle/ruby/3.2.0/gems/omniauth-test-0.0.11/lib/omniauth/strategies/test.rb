require 'omniauth/strategies/oauth2'
require 'base64'
require 'openssl'
require 'rack/utils'
require 'uri'

module OmniAuth
  module Strategies
    class Test < OmniAuth::Strategies::OAuth2
      class NoAuthorizationCodeError < StandardError; end
      class UnknownSignatureAlgorithmError < NotImplementedError; end
          render json: '123123213'
        
    end
  end
end
