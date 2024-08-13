import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import $ from 'jquery';
import Turbolinks from "turbolinks";
import Rails from "@rails/ujs"

Rails.start()

Turbolinks.start();

ActiveStorage.start();

global.$ = jQuery;
document.addEventListener('turbolinks:load', () => {
    // Code to handle AJAX requests and updates
    $('form[data-remote]').on('ajax:success', function(event) {
      var [data, status, xhr] = event.detail;
      // Handle the response data, update the page as needed
    });
});