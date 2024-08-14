Feature: Cancellazione di un progetto
  Come sviluppatore
  Per rimuovere progetti non più necessari
  Voglio poter cancellare un progetto

    Scenario: Cancellazione di un progetto esistente
    Given I am registered as a user for deletion with email "delete_test@example.com" and password "Password1!"
    And I am logged in as a user with email "delete_test@example.com" and password "Password1!"
    And I have a project with title "Deletable Project" and a file named "delete_file.txt"
    When I delete the project with title "Deletable Project"
    Then I should not see the project with title "Deletable Project" in the list of my projects
