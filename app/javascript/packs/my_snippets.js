document.addEventListener('DOMContentLoaded', function() {
    // Get elements
    const sortMenuButton = document.getElementById('sortMenuButton');
    const sortMenu = document.getElementById('sortMenu');
    const languageMenuButton = document.getElementById('languageMenuButton');
    const languageMenu = document.getElementById('languageMenu');
  
    // Toggle sort menu
    sortMenuButton.addEventListener('click', function(event) {
      event.stopPropagation();
      sortMenu.classList.toggle('hidden');
      languageMenu.classList.add('hidden'); // Close language menu if open
    });
  
    // Toggle language menu
    languageMenuButton.addEventListener('click', function(event) {
      event.stopPropagation();
      languageMenu.classList.toggle('hidden');
      sortMenu.classList.add('hidden'); // Close sort menu if open
    });
  
    // Close menus when clicking outside
    document.addEventListener('click', function() {
      sortMenu.classList.add('hidden');
      languageMenu.classList.add('hidden');
    });
  
    // Close menus when pressing the escape key
    document.addEventListener('keydown', function(event) {
      if (event.key === 'Escape') {
        sortMenu.classList.add('hidden');
        languageMenu.classList.add('hidden');
      }
    });
  });
  