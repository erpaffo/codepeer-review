// messages_channel.js (ripristinato)

document.addEventListener('turbolinks:load', () => {
  const messagesContainer = document.getElementById('messages');

  if (messagesContainer) {
    // Mantieni il rendering statico senza WebSocket
    console.log("Rendering dei messaggi statici");
  }
});
