FactoryBot.define do
  factory :project do
    title { "Titolo del Progetto" }
    description { "Descrizione del progetto." }
    visibility { "public" }
    association :user
  end
end
