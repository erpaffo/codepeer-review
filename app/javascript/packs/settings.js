document.addEventListener('turbolinks:load', function() {
    const form = document.querySelector('#disable-2fa-form');
  
    if (form) {
      form.addEventListener('ajax:success', function(event) {
        const responseData = event.detail[0];
        if (responseData.notice) {
          // Aggiorna il testo di stato e nasconde il pulsante
          document.querySelector('#two-factor-status').innerHTML = '<p class="text-red-500">Two-Factor Authentication is disabled</p>';
          form.style.display = 'none';
        }
      });
    }
  });
  