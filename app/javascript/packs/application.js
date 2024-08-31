import * as ActiveStorage from '@rails/activestorage';
import 'channels';
import $ from 'jquery';
import Turbolinks from "turbolinks";
import Rails from '@rails/ujs'
import Dropzone from 'dropzone';

Rails.start()

Turbolinks.start();

ActiveStorage.start();

document.addEventListener('turbolinks:load', () => {
    // Code to handle AJAX requests and updates
    $('form[data-remote]').on('ajax:success', function(event) {
      var [data, status, xhr] = event.detail;
      // Handle the response data, update the page as needed
    });
});


document.addEventListener('DOMContentLoaded', () => {
  const dropzone = document.querySelector('.dropzone');

  if (dropzone) {
    dropzone.addEventListener('dragover', () => {
      dropzone.classList.add('dragover');
    });

    dropzone.addEventListener('dragleave', () => {
      dropzone.classList.remove('dragover');
    });

    dropzone.addEventListener('drop', () => {
      dropzone.classList.remove('dragover');
    });
  }
});

// gallery view
document.addEventListener('DOMContentLoaded', () => {
  const slider = document.getElementById('project-slider');
  const prevBtn = document.getElementById('prev-btn');
  const nextBtn = document.getElementById('next-btn');
  
  const scrollAmount = slider.clientWidth; // How much to scroll with each click

  let scrollCount = 0;

  prevBtn.addEventListener('click', () => {
    if (scrollCount > 0) {
      slider.scrollBy({ left: -scrollAmount, behavior: 'smooth' });
      scrollCount--;
    }
  });

  nextBtn.addEventListener('click', () => {
    if (scrollCount < 10) { // limit to 10 scrolls
      slider.scrollBy({ left: scrollAmount, behavior: 'smooth' });
      scrollCount++;
    }
  });
});
