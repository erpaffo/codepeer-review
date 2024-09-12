FactoryBot.define do
  factory :feedback do
    content { Faker::Lorem.paragraph }
    association :user 
  end
end
