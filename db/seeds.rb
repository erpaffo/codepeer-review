# db/seeds.rb
Badge.create([
  {
    name: "Primo Progetto Creato",
    description: "Ottieni questo badge creando il tuo primo progetto.",
    icon: "badges/snippet_badge.png",
    criteria: { action: "create_project", count: 1 },
  },
  {
    name: "Collaboratore Attivo",
    description: "Lascia 3 feedback per ottenere questo badge.",
    icon: "badges/feedback_badge.png",
    criteria: { action: "leave_feedback", count: 3 },
  },
  {
    name: "Leader di Progetti",
    description: "Crea 5 progetti per ottenere questo badge.",
    icon: "badges/five_project_badge.png",
    criteria: { action: "create_project", count: 5 },
  }
])
