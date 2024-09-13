Feature: Create a Snippet Draft
  As a user
  I want to create a snippet and save it as a draft
  So that I can come back and edit it later

  Background:
    Given I am a registered user
    And I am logged in
    And I am on the "Create New Snippet" page

  Scenario: User creates a snippet draft
    When I fill in "Title" with "My Draft Snippet"
    And I fill in "Content" with "Some draft content"
    And I click "Save as Draft"
    Then I should be on the "My Snippets" page
    And I should see "My Draft Snippet"
    And the snippet should be marked as draft
