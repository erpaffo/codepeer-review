FactoryBot.define do
  factory :snippet do
    sequence(:title) { |n| "Snippet Title #{n}" }
    content { "Sample content for the snippet." }
    comment { "This is a comment for the snippet." }
    draft { false }
    favorite { false }
    association :user

    trait :draft do
      draft { true }
    end

    trait :favorite do
      favorite { true }
    end
  end
end
