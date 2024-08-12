import Rails from '@rails/ujs';
import * as ActiveStorage from '@rails/activestorage';
import 'channels';

Rails.start();
ActiveStorage.start();

document.addEventListener('turbolinks:load', () => {
    // Code to handle AJAX requests and updates
    $('form[data-remote]').on('ajax:success', function(event) {
      var [data, status, xhr] = event.detail;
      // Handle the response data, update the page as needed
    });
});