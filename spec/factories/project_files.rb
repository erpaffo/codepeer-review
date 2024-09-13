FactoryBot.define do
  factory :project_file do
    file { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test_file.txt'), 'text/plain') }
    project
  end
end
