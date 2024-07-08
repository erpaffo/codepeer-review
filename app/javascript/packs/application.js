import Rails from '@rails/ujs';
import Turbolinks from "turbolinks"
import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import 'jquery';
import 'bootstrap';

Rails.start()
Turbolinks.start()
ActiveStorage.start()

$(document).on('click', '.remove_fields', function(event) {
    $(this).prev('input[type=hidden]').val('1');
    $(this).closest('.nested-fields').hide();
    event.preventDefault();
  });
  
  $(document).on('click', '.add_fields', function(event) {
    var time = new Date().getTime();
    var regexp = new RegExp($(this).data('id'), 'g');
    $(this).before($(this).data('fields').replace(regexp, time));
    event.preventDefault();
  });

console.log("Javascript loaded!")