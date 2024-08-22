// app/assets/javascripts/application.js
$(document).on('turbolinks:load', function() {
    $('.mark-as-read').on('ajax:success', function(event) {
      var notificationId = $(this).closest('.notification').data('id');
      $('.notification[data-id="' + notificationId + '"]').addClass('read');
    });
  });
  
  document.querySelectorAll('.delete-notification').forEach(element => {
    element.addEventListener('ajax:success', (event) => {
      const [data, status, xhr] = event.detail;
      const notificationElement = element.closest('.notification');
      notificationElement.remove();
    });
  });