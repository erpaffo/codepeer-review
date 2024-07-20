// app/javascript/packs/toggle_favorite.js

document.addEventListener('turbolinks:load', () => {
    const favoriteButtons = document.querySelectorAll('.toggle-favorite');
  
    favoriteButtons.forEach(button => {
      button.addEventListener('click', (event) => {
        event.preventDefault();
        const snippetId = button.dataset.snippetId;
        const url = `/snippets/${snippetId}/toggle_favorite`;
  
        fetch(url, {
          method: 'PATCH',
          headers: {
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
            'Content-Type': 'application/json'
          }
        })
        .then(response => response.json())
        .then(data => {
          if (data.favorite) {
            button.textContent = 'Unfavorite';
          } else {
            button.textContent = 'Favorite';
          }
        })
        .catch(error => console.error('Error:', error));
      });
    });
  });
  