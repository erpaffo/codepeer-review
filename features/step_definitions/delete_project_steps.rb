Given('I am registered as a user for deletion with email {string} and password {string}') do |email, password|
  User.create!(email: email, password: password, confirmed_at: Time.now)
end

Given('I am logged in as a user for deletion with email {string} and password {string}') do |email, password|
  visit new_user_session_path
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log in'

  expect(page).to have_content('Dashboard')
end

Given('I have a project with title {string} and a file named {string}') do |title, file_name|
  @user = User.find_by(email: 'delete_test@example.com') || User.create!(email: 'delete_test@example.com', password: 'Password1!', confirmed_at: Time.now)

  file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', file_name), 'text/plain')

  @project = @user.projects.create!(
    title: title,
    description: 'This is a deletable project',
    visibility: 'public',
    project_files_attributes: [
      { file: file }
    ]
  )
end

When('I delete the project with title {string}') do |title|
  project = Project.find_by(title: title)
  visit edit_project_path(project)

  expect(page).to have_content('Delete Project')

  confirmation_value = "#{project.user.nickname}/#{project.title}"
  fill_in 'confirmation', with: confirmation_value

  page.accept_confirm do
    click_button 'Delete Project'
  end
end

Then('I should not see the project with title {string} in the list of my projects') do |title|
  visit projects_path
  expect(page).not_to have_content(title)
end
