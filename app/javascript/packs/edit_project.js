document.addEventListener("DOMContentLoaded", function() {
  var deleteProjectForm = document.querySelector("form[method='delete']");
  if (deleteProjectForm) {
    deleteProjectForm.addEventListener("submit", function(event) {
      var confirmationInput = document.querySelector("input[name='confirmation']");
      var expectedConfirmation = confirmationInput.placeholder;
      if (confirmationInput.value !== expectedConfirmation) {
        event.preventDefault();
        alert("Confirmation does not match. Project was not destroyed.");
      }
    });
  }
});
