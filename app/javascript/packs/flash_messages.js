document.addEventListener('DOMContentLoaded', function () {
    setTimeout(function () {
      var alerts = document.querySelectorAll('.flash-notice, .flash-alert');
      alerts.forEach(function (alert) {
        alert.classList.add('fade-out');
        setTimeout(function () {
          alert.remove();
        }, 500); 
      });
    }, 5000); 
  
    
    var closeButtons = document.querySelectorAll('.close-alert');
    closeButtons.forEach(function (button) {
      button.addEventListener('click', function () {
        var alert = this.parentElement;
        alert.classList.add('fade-out');
        setTimeout(function () {
          alert.remove();
        }, 500); 
      });
    });
  });
  