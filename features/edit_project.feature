Feature: Modifica del titolo e della descrizione di un progetto
  Come utente registrato
  Per aggiornare le informazioni del mio progetto
  Voglio modificare il titolo e la descrizione del progetto

  Scenario: Modifica del titolo e della descrizione
    Given I am logged in as a user for editing profile
    And I have a project with title "Old Title" and description "Old Description"
    When I update the project title to "New Title" and description to "New Description"
    Then I should see the project with title "New Title" and description "New Description"
