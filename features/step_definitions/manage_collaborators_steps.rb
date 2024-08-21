Given('I am logged in as a user to manage collaborators with email {string} and password {string}') do |email, password|
  @user = User.create!(email: email, password: password, confirmed_at: Time.now)

  visit new_user_session_path
  fill_in 'Email', with: email
  fill_in 'Password', with: password
  click_button 'Log in'

  expect(page).to have_content('Dashboard')
end

Given('I have a collaborative project with title {string}') do |title|
  file = Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'files', 'test_file.txt'), 'text/plain')

  @project = @user.projects.create!(
    title: title,
    description: 'A collaborative project',
    visibility: 'private',
    project_files_attributes: [{ file: file }]
  )
end

When('I invite a collaborator with email {string}') do |email|
  fill_in 'collaborator_emails_field', with: email
  select 'Full', from: 'collaborator_permissions'
  click_button 'Create Project'
end


Then('I should see {string} listed as a collaborator') do |email|
  visit edit_project_path(@project)
  expect(page).to have_content(email)
end

Given('{string} is already a collaborator') do |email|
  collaborator_user = User.create!(email: email, password: 'Password1!', confirmed_at: Time.now)
  @project.collaborators.create!(user: collaborator_user, permissions: 'full')
end

When('I remove the collaborator with email {string}') do |email|
  visit edit_project_path(@project)
  click_link('Delete', match: :first) # Assume the first delete link is for the correct collaborator
end

Then('I should not see {string} listed as a collaborator') do |email|
  visit edit_project_path(@project)
  expect(page).not_to have_content(email)
end
