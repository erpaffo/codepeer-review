Feature: Caricamento di un progetto
  Come utente registrato
  Per condividere il mio codice con altri utenti
  Voglio caricare un progetto sulla piattaforma

  Scenario: Caricamento di un progetto
    Given I am logged in as a user for project upload
    When I upload a new project with title "Test Project" and a file
    Then I should see the project with title "Test Project" in the list of my projects
