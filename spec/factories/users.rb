FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "Password123!" }
    first_name { "Test" }
    last_name  { "User" }
    nickname { "nickname" }
    phone_number { "123456789" }

    trait :with_profile_image do
      after(:create) do |user|
        user.profile_image.attach(
          io: File.open(Rails.root.join('spec', 'support', 'assets', 'profile_image.png')),
          filename: 'no_image_available.png', content_type: 'image/png'
        )
      end
    end

    after(:create) do |user|
      user.confirm if user.respond_to?(:confirm)
    end
  end
end
