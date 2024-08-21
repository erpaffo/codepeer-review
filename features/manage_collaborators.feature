Feature: Manage Collaborators
  Come proprietario di un progetto
  Per gestire i collaboratori
  Voglio aggiungere e rimuovere collaboratori dal progetto

  Scenario: Aggiungere un collaboratore al progetto
    Given I am logged in as a user to manage collaborators with email "owner@example.com" and password "Password1!"
    And I have a collaborative project with title "Collaborative Project"
    When I invite a collaborator with email "collaborator@example.com"
    Then I should see "collaborator@example.com" listed as a collaborator

  Scenario: Rimuovere un collaboratore dal progetto
    Given I am logged in as a user to manage collaborators with email "owner@example.com" and password "Password1!"
    And I have a collaborative project with title "Collaborative Project"
    And "collaborator@example.com" is already a collaborator
    When I remove the collaborator with email "collaborator@example.com"
    Then I should not see "collaborator@example.com" listed as a collaborator
