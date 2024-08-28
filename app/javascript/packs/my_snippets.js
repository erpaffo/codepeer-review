document.addEventListener('DOMContentLoaded', function() {
  // Get elements
  const sortMenuButton = document.getElementById('sortMenuButton');
  const sortMenu = document.getElementById('sortMenu');
  const languageMenuButton = document.getElementById('languageMenuButton');
  const languageMenu = document.getElementById('languageMenu');

  function toggleSortMenu(event) {
    event.stopPropagation();
    sortMenu.classList.toggle('hidden');
    languageMenu.classList.add('hidden'); // Close language menu if open
  }

  function toggleLanguageMenu(event) {
    event.stopPropagation();
    languageMenu.classList.toggle('hidden');
    sortMenu.classList.add('hidden'); // Close sort menu if open
  }

  // Add event listeners
  sortMenuButton.addEventListener('click', toggleSortMenu);
  languageMenuButton.addEventListener('click', toggleLanguageMenu);

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

  // Reattach event listeners when needed
  document.addEventListener('turbolinks:load', function() {
    sortMenuButton.removeEventListener('click', toggleSortMenu);
    languageMenuButton.removeEventListener('click', toggleLanguageMenu);

    sortMenuButton.addEventListener('click', toggleSortMenu);
    languageMenuButton.addEventListener('click', toggleLanguageMenu);
  });
});
