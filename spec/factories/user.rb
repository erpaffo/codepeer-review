FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email } 
    password { "Password1!" }
    password_confirmation { "Password1!" }
    first_name { Faker::Name.first_name }
    last_name { Faker::Name.last_name }
    confirmed_at { Time.current }
  end
end
