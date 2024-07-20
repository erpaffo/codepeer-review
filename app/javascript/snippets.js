document.addEventListener("DOMContentLoaded", function() {
    function setupFavoriteToggles() {
      document.querySelectorAll(".toggle-favorite").forEach(function(element) {
        element.addEventListener("ajax:success", function(event) {
          const snippetId = event.currentTarget.id.replace("favorite-snippet-", "");
          const favoriteStatus = event.detail[0].favorite;
          const starElement = document.getElementById(`favorite-snippet-${snippetId}`);
  
          if (favoriteStatus) {
            starElement.classList.add("favorite");   // Aggiungi classe per colore pieno
          } else {
            starElement.classList.remove("favorite");   // Rimuovi classe per colore pieno
          }
        });
      });
    }
  
    setupFavoriteToggles();
  
    // Observe changes in the DOM to reapply event listeners (e.g., after creating a new snippet)
    const observer = new MutationObserver(setupFavoriteToggles);
    observer.observe(document.body, { childList: true, subtree: true });
  });

  document.addEventListener("turbolinks:load", () => {
    const sortLinks = document.querySelectorAll(".dropdown-menu .dropdown-item");
    sortLinks.forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        const url = link.getAttribute("href");
  
        fetch(url, {
          headers: {
            "Accept": "text/javascript"
          }
        })
        .then(response => response.text())
        .then(data => {
          document.getElementById("snippets_list").innerHTML = data;
        });
      });
    });
  
    const languageLinks = document.querySelectorAll("#languageMenu .dropdown-item");
    languageLinks.forEach((link) => {
      link.addEventListener("click", (event) => {
        event.preventDefault();
        const url = link.getAttribute("href");
  
        fetch(url, {
          headers: {
            "Accept": "text/javascript"
          }
        })
        .then(response => response.text())
        .then(data => {
          document.getElementById("snippets_list").innerHTML = data;
        });
      });
    });
  });
  
  