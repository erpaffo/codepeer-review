Given('I am registered as a user with email {string} and password {string}') do |email, password|
  User.create!(email: email, password: password, confirmed_at: Time.now)
end

Given('I am logged in as a user with email {string} and password {string}') do |email, password|
  visit new_user_session_path
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log in'

  expect(page).to have_content('Dashboard')
end

Given('I have a project with a file named {string}') do |file_name|
  @user = User.find_by(email: 'edit_test@example.com') || User.create!(email: 'edit_test@example.com', password: 'Password1!', confirmed_at: Time.now)

  file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', file_name), 'text/plain')

  @project = @user.projects.create!(
    title: 'Test Project',
    description: 'This is a test project with a file',
    visibility: 'public',
    project_files_attributes: [
      { file: file }
    ]
  )
end

When('I navigate to the edit page of the file named {string}') do |file_name|
  @file = @project.project_files.find_by(file: file_name)
  visit edit_file_project_path(@project, file_id: @file.id)
end

When('I change the content to {string}') do |new_content|
  page.execute_script("monaco.editor.getModels()[0].setValue('#{new_content}')")
  click_button 'Save File'
end

Then('I should see the updated content {string} in the project file') do |expected_content|
  visit edit_file_project_path(@project, file_id: @file.id)
  actual_content = page.evaluate_script("monaco.editor.getModels()[0].getValue()")
  expect(actual_content).to eq(expected_content)
end
