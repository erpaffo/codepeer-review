document.addEventListener('DOMContentLoaded', () => {
  const sidebarToggle = document.querySelector('.sidebar-toggle');
  const sidebarClose = document.querySelector('.sidebar-close');
  const sidebar = document.querySelector('.sidebar');
  const body = document.body;

  // Verifica che gli elementi siano trovati
  console.log('Sidebar Toggle:', sidebarToggle);
  console.log('Sidebar Close:', sidebarClose);
  console.log('Sidebar:', sidebar);

  sidebarToggle.addEventListener('click', () => {
    body.classList.toggle('sidebar-open');
    console.log('Sidebar toggled, class added/removed');
    console.log('Body class list:', body.classList);
    console.log('Sidebar transform style:', getComputedStyle(sidebar).transform);
  });

  sidebarClose.addEventListener('click', () => {
    body.classList.remove('sidebar-open');
    console.log('Sidebar closed, class removed');
  });
});
