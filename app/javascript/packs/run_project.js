document.addEventListener('DOMContentLoaded', () => {
    const runButton = document.getElementById('run-code');
    const outputContainer = document.getElementById('output');

    if (!runButton) {
        console.error('Run Code button not found!');
        return;
    }

    runButton.addEventListener('click', (e) => {
        e.preventDefault();
        
        // Prendi il codice e il linguaggio dalla vista
        const code = window.monacoEditor ? window.monacoEditor.getValue() : '';
        const language = document.getElementById('language-select').value; // Ora abbiamo il linguaggio dal campo hidden
        const projectId = window.location.pathname.split('/')[2]; // Assumendo che la rotta sia /projects/:id/edit_file

        if (!code.trim()) {
            outputContainer.innerHTML = `<pre style="color: red;">Code is empty.</pre>`;
            return;
        }

        // Disabilita il pulsante per prevenire clic multipli
        runButton.disabled = true;
        runButton.innerText = 'Running...';

        fetch(`/projects/${projectId}/run_code`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            body: JSON.stringify({ code: code, language: language })
        })
        .then(response => response.json())
        .then(data => {
            if (data.output) {
                outputContainer.innerHTML = `<pre>${escapeHtml(data.output)}</pre>`;
            } else if (data.error) {
                outputContainer.innerHTML = `<pre style="color: red;">${escapeHtml(data.error)}</pre>`;
            } else {
                outputContainer.innerHTML = `<pre style="color: red;">Unknown response from server.</pre>`;
            }
        })
        .catch(error => {
            console.error('Error:', error);
            outputContainer.innerHTML = `<pre style="color: red;">An error occurred while running the code.</pre>`;
        })
        .finally(() => {
            runButton.disabled = false;
            runButton.innerText = 'Run Code';
        });
    });

    // Funzione per sanificare l'output e prevenire XSS
    function escapeHtml(text) {
        const map = {
            '&': '&amp;',
            '<': '&lt;',
            '>': '&gt;',
            '"': '&quot;',
            "'": '&#039;'
        };
        return text.replace(/[&<>"']/g, function(m) { return map[m]; });
    }
});
