export function setupRunCodeButton() {
    const runButton = document.getElementById('run-code');
    if (runButton) {
      runButton.addEventListener('click', () => {
        const code = window.monacoEditor.getValue();
        // Chiamata AJAX per eseguire il codice (implementare nel backend)
        fetch('/run_code', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
          },
          body: JSON.stringify({ code: code, language: 'python' }) // Cambia il linguaggio se necessario
        })
        .then(response => response.json())
        .then(data => {
          // Mostra l'output del codice (implementare nel backend)
          console.log(data.output);
        });
      });
    }
  }