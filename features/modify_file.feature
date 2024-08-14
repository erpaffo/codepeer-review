Feature: Modifica di un file
  Come sviluppatore
  Per migliorare il codice esistente
  Voglio modificare un file direttamente nella piattaforma

  Scenario: Modifica di un file
    Given I am registered as a user with email "edit_test@example.com" and password "Password1!"
    And I am logged in as a user with email "edit_test@example.com" and password "Password1!"
    And I have a project with a file named "test_file.txt"
    When I navigate to the edit page of the file named "test_file.txt"
    And I change the content to "New content"
    Then I should see the updated content "New content" in the project file
