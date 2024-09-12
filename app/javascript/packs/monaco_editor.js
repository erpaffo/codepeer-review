let monacoEditor = null;

function getLanguageFromFileExtension(fileName) {
    const extension = fileName.split('.').pop().toLowerCase();
    switch (extension) {
        case 'py': return 'python';
        case 'js': return 'javascript';
        case 'html': return 'html';
        case 'css': return 'css';
        case 'rb': return 'ruby';
        case 'c': return 'c';
        case 'cpp': return 'cpp';
        case 'java': return 'java';
        case 'ts': return 'typescript';
        case 'go': return 'go';
        case 'php': return 'php';
        case 'swift': return 'swift';
        case 'sh': return 'shell';
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

    if (monacoEditor) {
        monacoEditor.dispose();
    }

    let content = editorElement.dataset.content;

    try {
        monacoEditor = monaco.editor.create(editorElement, {
            value: content,
            language: language,
            theme: theme,
            fontSize: parseInt(document.getElementById('font-size').value, 10),
            minimap: { enabled: document.getElementById('minimap-select').checked },
            automaticLayout: true,
            lineNumbers: document.getElementById('highlight-line').checked ? 'on' : 'off',
            multiCursorModifier: document.getElementById('multi-cursor').checked ? 'alt' : null,
            lineDecorationsWidth: document.getElementById('highlight-line').checked ? '2px' : '0px',
            autoClosingBrackets: document.getElementById('auto-close-brackets').checked ? 'always' : 'never'
        });

        // Rileva ridimensionamenti e chiama layout per aggiornare l'editor
        new ResizeObserver(() => {
            monacoEditor.layout();
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

    document.getElementById('theme-select').addEventListener('change', initializeMonacoEditor);
    document.getElementById('font-size').addEventListener('input', initializeMonacoEditor);
    document.getElementById('minimap-select').addEventListener('change', initializeMonacoEditor);
    document.getElementById('multi-cursor').addEventListener('change', initializeMonacoEditor);
    document.getElementById('highlight-line').addEventListener('change', initializeMonacoEditor);
    document.getElementById('auto-close-brackets').addEventListener('change', initializeMonacoEditor);

    // Save the content of the editor to the hidden input field when the "Save File" button is clicked
    document.getElementById('save-file').addEventListener('click', () => {
        if (monacoEditor) {
            const content = monacoEditor.getValue();
            console.log('Content to be saved:', content);  // Debug log

            document.getElementById('file-content').value = content;
            document.getElementById('edit-file-form').submit();
        }
    });
});

window.addEventListener('beforeunload', () => {
    if (monacoEditor) {
        monacoEditor.dispose();
        monacoEditor = null;
    }
});
