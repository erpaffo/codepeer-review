import * as monaco from 'monaco-editor';

export function initializeMonacoEditor() {
  const editorElement = document.getElementById('code-editor');
  if (editorElement) {
    const editor = monaco.editor.create(editorElement, {
      value: editorElement.dataset.content,
      language: 'python', // Puoi cambiare la modalità in base al linguaggio
      theme: 'vs-dark'
    });

    // Salva l'istanza dell'editor per poterla usare nei pulsanti
    window.monacoEditor = editor;
  }
}
