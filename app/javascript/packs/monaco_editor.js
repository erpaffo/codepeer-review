window.monacoEditor = null; // Definisci monacoEditor globalmente

function getLanguageFromFileExtension(fileName) {
    const extension = fileName.split('.').pop().toLowerCase();
    switch (extension) {
        case 'py': return 'python';
        case 'js': return 'javascript';
        case 'rb': return 'ruby';
        case 'c': return 'c';
        case 'cpp': return 'cpp';
        case 'java': return 'java';
        case 'rs': return 'rust';
        default: return 'plaintext';
    }
}

function initializeMonacoEditor() {
    const editorElement = document.getElementById('code-editor');
    if (!editorElement) {
        console.error('Monaco Editor container element not found!');
        return;
    }

    const fileIdentifierElement = document.getElementById('file-identifier');
    if (!fileIdentifierElement) {
        console.error('File identifier element not found!');
        return;
    }

    const language = getLanguageFromFileExtension(fileIdentifierElement.value);
    const theme = document.getElementById('theme-select').value;

    if (window.monacoEditor) {
        window.monacoEditor.dispose();
    }

    let content = editorElement.getAttribute('data-content') || '';

    try {
        window.monacoEditor = monaco.editor.create(editorElement, {
            value: content,
            language: language,
            theme: theme,
            fontSize: parseInt(document.getElementById('font-size').value, 10),
            minimap: { enabled: document.getElementById('minimap-select').checked },
            automaticLayout: true,
            lineNumbers: document.getElementById('highlight-line').checked ? 'on' : 'off',
            multiCursorModifier: document.getElementById('multi-cursor').checked ? 'alt' : 'ctrlCmd',
            autoClosingBrackets: document.getElementById('auto-close-brackets').checked ? 'always' : 'never'
        });

        // Rileva ridimensionamenti e chiama layout per aggiornare l'editor
        new ResizeObserver(() => {
            window.monacoEditor.layout();
        }).observe(editorElement);

    } catch (error) {
        console.error('Error initializing Monaco Editor:', error);
    }
}

function loadMonacoEditor() {
    if (typeof window.require !== 'undefined') {
        if (!window.require.monacoConfigured) {
            window.require.config({ paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.30.0/min/vs' }});
            window.require.monacoConfigured = true;
        }
        window.require(['vs/editor/editor.main'], function() {
            initializeMonacoEditor();
        });
    } else {
        setTimeout(loadMonacoEditor, 50);
    }
}

document.addEventListener('DOMContentLoaded', () => {
    loadMonacoEditor();

    // Aggiungi Event Listeners per i controlli dell'editor
    const controls = [
        'theme-select',
        'font-size',
        'minimap-select',
        'multi-cursor',
        'highlight-line',
        'auto-close-brackets'
    ];

    controls.forEach(id => {
        const element = document.getElementById(id);
        if (element) {
            element.addEventListener('change', initializeMonacoEditor);
            if (element.type === 'number') {
                element.addEventListener('input', initializeMonacoEditor);
            }
        }
    });

    // Save the content of the editor to the hidden input field when the "Save File" button is clicked
    const saveButton = document.getElementById('save-file');
    if (saveButton) {
        saveButton.addEventListener('click', (e) => {
            e.preventDefault();
            if (window.monacoEditor) {
                const content = window.monacoEditor.getValue();
                console.log('Content to be saved:', content);  // Debug log

                document.getElementById('file-content').value = content;
                document.getElementById('edit-file-form').submit();
            }
        });
    }
});

window.addEventListener('beforeunload', () => {
    if (window.monacoEditor) {
        window.monacoEditor.dispose();
        window.monacoEditor = null;
    }
});
