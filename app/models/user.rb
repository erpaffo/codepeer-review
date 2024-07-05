class User < ApplicationRecord
       devise :database_authenticatable, :registerable,
              :recoverable, :rememberable, :validatable,
              :omniauthable, omniauth_providers: %i[google_oauth2 github gitlab]

       def self.from_omniauth(auth)
         where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
           user.email = auth.info.email
           user.password = Devise.friendly_token[0, 20]
           user.first_name = auth.info.first_name
           user.last_name = auth.info.last_name
         end
       end
     end
