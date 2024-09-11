// notifications.js
document.addEventListener("DOMContentLoaded", () => {
  document.querySelectorAll(".delete-notification").forEach((button) => {
    button.addEventListener("click", (event) => {
      event.preventDefault();
      const url = button.getAttribute("href");

      fetch(url, {
        method: "DELETE",
        headers: {
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').getAttribute("content"),
          "Content-Type": "application/json",
        },
      })
        .then((response) => {
          if (response.ok) {
            const notificationItem = button.closest(".notification");
            notificationItem.remove(); // Rimuove l'elemento dalla pagina
            const notificationDot = document.querySelector(".notifications-link .notification-dot");
            if (notificationDot && document.querySelectorAll(".notification:not(.read)").length === 0) {
              notificationDot.style.display = "none";
            }
          }
        })
        .catch((error) => console.error("Error:", error));
    });
  });
});
