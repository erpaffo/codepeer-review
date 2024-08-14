Feature: View project statistics
  As a project owner
  I want to view the statistics of my project
  So that I can see how many people have viewed and favorited my project

  Scenario: Viewing project statistics
    Given I am logged in as a user
    And I have a project with title "My Awesome Project"
    And the project has 5 unique views
    And the project has been favorited by 3 users
    When I visit the statistics page of the project
    Then I should see "5" as the unique view count
    And I should see "3" as the favorite count
