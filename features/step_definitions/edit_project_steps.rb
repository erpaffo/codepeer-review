Given('I am logged in as a user for editing profile') do
  @user = User.create!(email: 'edit_profile_test@example.com', password: 'Password1!', confirmed_at: Time.now)

  visit new_user_session_path
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: @user.password
  click_button 'Log in'

  expect(page).to have_content('Dashboard')

  visit edit_profile_path
  expect(page).to have_content('Edit Profile')
end

Given('I have a project with title {string} and description {string}') do |title, description|
  user = User.first || User.create!(email: 'test@example.com', password: 'Password1!', confirmed_at: Time.now)

  file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test_file.txt'), 'text/plain')

  @project = @user.projects.create!(
    title: title,
    description: description,
    visibility: 'public',
    project_files_attributes: [
      { file: file }
    ]
  )
end

When('I update the project title to {string} and description to {string}') do |new_title, new_description|
  visit edit_project_path(@project)
  fill_in 'Title', with: new_title
  fill_in 'Description', with: new_description
  click_button 'Update Project'
end

Then('I should see the project with title {string} and description {string}') do |expected_title, expected_description|
  visit project_path(@project)
  expect(page).to have_content(expected_title)
  expect(page).to have_content(expected_description)
end
