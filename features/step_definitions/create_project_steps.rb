Given('I am logged in as a user for project upload') do
  @user = User.create!(email: 'upload_test@example.com', password: 'Password1!', confirmed_at: Time.now)

  visit new_user_session_path
  fill_in 'Email', with: @user.email
  fill_in 'Password', with: @user.password
  click_button 'Log in'

  expect(page).to have_content('Dashboard')
end

When('I upload a new project with title {string} and a file') do |title|
  visit new_project_path

  fill_in 'Title', with: title
  fill_in 'Description', with: 'This is a test project'

  attach_file('project_project_files_attributes_0_file', Rails.root.join('spec', 'fixtures', 'files', 'test_file.txt'))
  click_button 'Create Project'
end

Then('I should see the project with title {string} in the list of my projects') do |title|
  visit projects_path
  expect(page).to have_content(title)
end
