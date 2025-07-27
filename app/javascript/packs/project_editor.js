// Project Editor JavaScript
document.addEventListener('DOMContentLoaded', () => {
  let monacoEditor = null;
  let currentFileId = null;
  let currentFileName = null;
  const projectId = window.location.pathname.split('/')[2];

  // Inizializza Monaco Editor
  function initializeMonacoEditor() {
    if (typeof window.require === 'undefined') {
      setTimeout(initializeMonacoEditor, 100);
      return;
    }

    if (!window.require.monacoConfigured) {
      window.require.config({ 
        paths: { 
          'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.30.0/min/vs' 
        }
      });
      window.require.monacoConfigured = true;
    }

    window.require(['vs/editor/editor.main'], function() {
      const editorElement = document.getElementById('code-editor');
      if (!editorElement) return;

      const theme = document.getElementById('theme-select').value;
      const fontSize = parseInt(document.getElementById('font-size').value, 10);

      monacoEditor = monaco.editor.create(editorElement, {
        value: '// Select a file to start editing',
        language: 'plaintext',
        theme: theme,
        fontSize: fontSize,
        minimap: { enabled: true },
        automaticLayout: true,
        lineNumbers: 'on',
        multiCursorModifier: 'alt',
        autoClosingBrackets: 'always',
        scrollBeyondLastLine: false,
        wordWrap: 'on'
      });

      // Ridimensiona l'editor quando cambia la dimensione della finestra
      new ResizeObserver(() => { 
        if (monacoEditor) monacoEditor.layout(); 
      }).observe(editorElement);
    });
  }

  // Carica il contenuto di un file
  async function loadFileContent(fileId, fileName) {
    try {
      const response = await fetch(`/projects/${projectId}/show_file/${fileId}.json`);
      const data = await response.json();
      
      if (data.file_content) {
        currentFileId = fileId;
        currentFileName = fileName;
        
        // Aggiorna l'editor con il contenuto del file
        if (monacoEditor) {
          const language = getLanguageFromFileName(fileName);
          monaco.editor.setModelLanguage(monacoEditor.getModel(), language);
          monacoEditor.setValue(data.file_content);
        }
        
        // Evidenzia il file selezionato
        document.querySelectorAll('.file-item').forEach(item => {
          item.classList.remove('bg-blue-600');
          item.classList.add('bg-gray-700');
        });
        
        const selectedFile = document.querySelector(`[data-file-id="${fileId}"]`);
        if (selectedFile) {
          selectedFile.classList.remove('bg-gray-700');
          selectedFile.classList.add('bg-blue-600');
        }
      }
    } catch (error) {
      console.error('Error loading file:', error);
      showOutput('Error loading file content', 'error');
    }
  }

  // Salva il file corrente
  async function saveCurrentFile() {
    if (!currentFileId || !monacoEditor) {
      showOutput('No file selected for saving', 'error');
      return;
    }

    try {
      const content = monacoEditor.getValue();
      const formData = new FormData();
      formData.append('project_file[file]', content);

      const response = await fetch(`/projects/${projectId}/update_file/${currentFileId}`, {
        method: 'PATCH',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        },
        body: formData
      });

      if (response.ok) {
        const result = await response.json();
        showOutput(result.message || 'File saved successfully', 'success');
      } else {
        const error = await response.json();
        showOutput(`Error saving file: ${error.error}`, 'error');
      }
    } catch (error) {
      console.error('Error saving file:', error);
      showOutput('Error saving file', 'error');
    }
  }

  // Esegui il codice corrente
  async function runCurrentCode() {
    if (!currentFileId || !monacoEditor) {
      showOutput('No file selected for execution', 'error');
      return;
    }

    try {
      const code = monacoEditor.getValue();
      const fileName = currentFileName;

      const response = await fetch(`/projects/${projectId}/run_code`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        },
        body: JSON.stringify({ 
          code: code, 
          file_identifier: fileName 
        })
      });

      const data = await response.json();
      
      if (data.output) {
        showOutput(data.output, 'success');
      } else if (data.error) {
        showOutput(data.error, 'error');
      }
    } catch (error) {
      console.error('Error running code:', error);
      showOutput('Error executing code', 'error');
    }
  }

  // Crea un nuovo file
  async function createNewFile(fileName, extension) {
    try {
      const formData = new FormData();
      formData.append('file_name', fileName);
      formData.append('extension', extension);

      const response = await fetch(`/projects/${projectId}/create_file`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        },
        body: formData
      });

      if (response.ok) {
        const result = await response.json();
        showOutput(result.message || 'File created successfully', 'success');
        // Ricarica la pagina per mostrare il nuovo file
        setTimeout(() => window.location.reload(), 1000);
      } else {
        const error = await response.json();
        showOutput(`Error creating file: ${error.error}`, 'error');
      }
    } catch (error) {
      console.error('Error creating file:', error);
      showOutput('Error creating file', 'error');
    }
  }

  // Sincronizza i file con il container Docker
  async function syncFilesWithDocker() {
    try {
      const syncButton = document.getElementById('sync-files');
      syncButton.disabled = true;
      syncButton.textContent = 'Syncing...';
      
      const response = await fetch(`/projects/${projectId}/sync_files`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        const result = await response.json();
        showOutput(result.message || 'Files synchronized successfully', 'success');
      } else {
        const error = await response.json();
        showOutput(`Error syncing files: ${error.error}`, 'error');
      }
    } catch (error) {
      console.error('Error syncing files:', error);
      showOutput('Error syncing files', 'error');
    } finally {
      const syncButton = document.getElementById('sync-files');
      syncButton.disabled = false;
      syncButton.textContent = 'Sync Files';
    }
  }

  // Mostra output nel pannello di output
  function showOutput(message, type = 'info') {
    const outputContainer = document.getElementById('code-output');
    const outputContent = document.getElementById('output-content');
    
    if (outputContainer && outputContent) {
      outputContainer.classList.remove('hidden');
      
      const timestamp = new Date().toLocaleTimeString();
      const colorClass = type === 'error' ? 'text-red-400' : type === 'success' ? 'text-green-400' : 'text-gray-300';
      
      outputContent.innerHTML += `<div class="mb-1">
        <span class="text-gray-500 text-xs">[${timestamp}]</span>
        <span class="${colorClass}">${escapeHtml(message)}</span>
      </div>`;
      
      outputContent.scrollTop = outputContent.scrollHeight;
    }
  }

  // Utility functions
  function getLanguageFromFileName(fileName) {
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

  // Event listeners
  document.addEventListener('click', (e) => {
    // Edit file button
    if (e.target.classList.contains('edit-file-btn')) {
      const fileItem = e.target.closest('.file-item');
      const fileId = fileItem.dataset.fileId;
      const fileName = fileItem.dataset.fileName;
      loadFileContent(fileId, fileName);
    }

    // Run file button
    if (e.target.classList.contains('run-file-btn')) {
      const fileItem = e.target.closest('.file-item');
      const fileId = fileItem.dataset.fileId;
      const fileName = fileItem.dataset.fileName;
      loadFileContent(fileId, fileName).then(() => {
        setTimeout(runCurrentCode, 100);
      });
    }

    // Save file button
    if (e.target.id === 'save-file') {
      saveCurrentFile();
    }

    // Run code button
    if (e.target.id === 'run-code') {
      runCurrentCode();
    }

    // New file button
    if (e.target.id === 'new-file') {
      document.getElementById('new-file-modal').classList.remove('hidden');
    }

    // Create file button
    if (e.target.id === 'create-file-btn') {
      const fileName = document.getElementById('new-file-name').value;
      const extension = document.getElementById('new-file-extension').value;
      
      if (fileName.trim()) {
        createNewFile(fileName, extension);
        document.getElementById('new-file-modal').classList.add('hidden');
        document.getElementById('new-file-name').value = '';
      } else {
        showOutput('Please enter a file name', 'error');
      }
    }

    // Cancel new file button
    if (e.target.id === 'cancel-new-file') {
      document.getElementById('new-file-modal').classList.add('hidden');
      document.getElementById('new-file-name').value = '';
    }

    // Clear output button
    if (e.target.id === 'clear-output') {
      document.getElementById('output-content').innerHTML = '';
      document.getElementById('code-output').classList.add('hidden');
    }

    // Sync files button
    if (e.target.id === 'sync-files') {
      syncFilesWithDocker();
    }
  });

  // Theme selector change
  document.getElementById('theme-select').addEventListener('change', (e) => {
    if (monacoEditor) {
      monaco.editor.setTheme(e.target.value);
    }
  });

  // Font size change
  document.getElementById('font-size').addEventListener('change', (e) => {
    if (monacoEditor) {
      monacoEditor.updateOptions({ fontSize: parseInt(e.target.value, 10) });
    }
  });

  // Keyboard shortcuts
  document.addEventListener('keydown', (e) => {
    // Ctrl+S per salvare
    if (e.ctrlKey && e.key === 's') {
      e.preventDefault();
      saveCurrentFile();
    }

    // Ctrl+R per eseguire
    if (e.ctrlKey && e.key === 'r') {
      e.preventDefault();
      runCurrentCode();
    }

    // Ctrl+N per nuovo file
    if (e.ctrlKey && e.key === 'n') {
      e.preventDefault();
      document.getElementById('new-file-modal').classList.remove('hidden');
    }
  });

  // Inizializza l'editor quando la pagina è caricata
  initializeMonacoEditor();

  // Mostra messaggio di benvenuto
  showOutput('Project editor loaded. Select a file to start editing or create a new one.', 'info');
}); 