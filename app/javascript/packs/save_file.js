export function setupSaveFileButton() {
    const saveButton = document.getElementById('save-file');
    if (saveButton) {
      saveButton.addEventListener('click', () => {
        const form = document.getElementById('edit-file-form');
        const hiddenField = form.querySelector('input[type=hidden][name="project_file[file]"]');
        hiddenField.value = window.monacoEditor.getValue();
  
        form.submit();
      });
    }
  }