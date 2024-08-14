Given('I am logged in as a user') do
  @user = User.create!(email: 'test@example.com', password: 'Password1!', confirmed_at: Time.now)

  visit new_user_session_path
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: @user.password
  click_button 'Log in'

  expect(page).to have_content('Dashboard')
end


Given('I have a project with title {string}') do |title|
  user = User.first || User.create!(email: 'test@example.com', password: 'password')

  file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test_file.txt'), 'text/plain')

  @project = user.projects.create!(
    title: title,
    description: 'This is an awesome project',
    visibility: 'public',
    project_files_attributes: [
      { file: file }
    ]
  )
end


Given('the project has {int} unique views') do |view_count|
  view_count.times do
    ProjectView.create!(project: @project, user: User.create!(email: Faker::Internet.email, password: 'PPasswoq1rd1_!'))
  end
end

Given('the project has been favorited by {int} users') do |favorite_count|
  favorite_count.times do
    @project.favorites.create!(user: User.create!(email: Faker::Internet.email, password: 'Password1!'))
  end
end

When('I visit the statistics page of the project') do
  visit stats_project_path(@project)
end

Then('I should see {string} as the unique view count') do |view_count|
  expect(page).to have_content("Unique Views: #{view_count}")
end

Then('I should see {string} as the favorite count') do |favorite_count|
  expect(page).to have_content("Favorites: #{favorite_count}")
end
