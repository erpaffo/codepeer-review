FactoryBot.define do
  factory :snippet do
    title { "Test Snippet" }
    content { "This is some test content for the snippet." }
    comment { "This is a test comment." }
    favorite { false }
    draft { false }
    association :user

    trait :draft do
      draft { true }
    end

    trait :favorite do
      favorite { true }
    end
  end
end
