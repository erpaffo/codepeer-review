FactoryBot.define do
  factory :badge do
    name { "Badge Name" }
    description { "Badge Description" }
    icon { "badge_icon.png" }
    criteria { { 'type' => 'projects_count', 'value' => 1 } }
  end
end
