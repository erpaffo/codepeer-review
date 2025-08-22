// Project Editor JavaScript
document.addEventListener('DOMContentLoaded', () => {
  let monacoEditor = null;
  let currentFileId = null;
  let currentFileName = null;
  const projectId = window.location.pathname.split('/')[2];
  const editorContainer = document.getElementById('code-editor-wrapper') || document.getElementById('code-editor');

  // Inizializza Monaco Editor
  function initializeMonacoEditor() {
    // Ensure AMD loader exists (from loader.js)
    if (typeof window.require === 'undefined' || !window.require) {
      setTimeout(initializeMonacoEditor, 150);
      return;
    }

    if (!window.require.monacoConfigured) {
      window.require.config({ 
        paths: { 'vs': 'https://cdn.jsdelivr.net/npm/monaco-editor@0.30.0/min/vs' }
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

      // Esponi l'istanza per split_pane.js
      editorElement._monacoInstance = monacoEditor;

      // Ridimensiona l'editor quando cambia la dimensione della finestra
      try {
        new ResizeObserver(() => { 
          if (monacoEditor) monacoEditor.layout(); 
        }).observe(editorContainer);
      } catch(e) {
        window.addEventListener('resize', () => { if (monacoEditor) monacoEditor.layout(); });
      }
    });
  }

  // Render file tree (simple, flat path -> nested UL)
  function renderFileTree() {
    const tree = document.getElementById('file-tree');
    if (!tree) return;
    const files = JSON.parse(tree.dataset.files || '[]');
    // Build nested structure
    const root = {};
    files.forEach(({id, path}) => {
      const parts = path.split('/');
      let node = root;
      parts.forEach((part, idx) => {
        node.children = node.children || {};
        node.children[part] = node.children[part] || {};
        if (idx === parts.length - 1) {
          node.children[part].__file = { id, name: path };
        }
        node = node.children[part];
      });
    });

    function createList(node, basePath = '') {
      const ul = document.createElement('ul');
      ul.className = 'text-gray-300 text-sm pl-3';
      const entries = Object.entries(node.children || {});
      entries.forEach(([name, child]) => {
        const li = document.createElement('li');
        const isFile = !!child.__file;
        if (isFile) {
          li.innerHTML = `<button class="file-item text-left hover:text-white" data-file-id="${child.__file.id}" data-file-name="${child.__file.name}">📄 ${name}</button>`;
        } else {
          li.innerHTML = `<details open class="group">
            <summary class="cursor-pointer select-none hover:text-white">📁 ${name}</summary>
          </details>`;
          const details = li.querySelector('details');
          details.appendChild(createList(child, basePath + name + '/'));
        }
        ul.appendChild(li);
      });
      return ul;
    }

    tree.innerHTML = '';
    const ul = createList(root);
    tree.appendChild(ul);

    // Auto-seleziona il primo file disponibile e caricalo
    const firstBtn = tree.querySelector('.file-item[data-file-id]');
    if (firstBtn && firstBtn.dataset.fileId && firstBtn.dataset.fileName) {
      loadFileContent(firstBtn.dataset.fileId, firstBtn.dataset.fileName);
    }
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
        // Evidenziazione minimale tramite title
        const selectedFile = document.querySelector(`[data-file-id="${fileId}"]`);
        if (selectedFile) selectedFile.title = 'Selected';
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
    // Toggle file tree
    if (e.target && e.target.id === 'toggle-file-tree') {
      const ft = document.getElementById('file-tree');
      if (ft) ft.style.display = (ft.style.display === 'none' ? '' : 'none');
    }

    // Edit file button
    if (e.target.classList.contains('edit-file-btn')) {
      const fileItem = e.target.closest('.file-item');
      if (!fileItem || !fileItem.dataset) return;
      const fileId = fileItem.dataset.fileId;
      const fileName = fileItem.dataset.fileName;
      if (fileId && fileName) loadFileContent(fileId, fileName);
    }

    // Click dal tree
    if (e.target.classList.contains('file-item') && e.target.dataset && e.target.dataset.fileId) {
      const fileId = e.target.dataset.fileId;
      const fileName = e.target.dataset.fileName;
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
  renderFileTree();

  // Resize verticale tra editor e console
  (function initVerticalResize() {
    const divider = document.getElementById('h-divider');
    if (!divider || !editorContainer) return;
    const output = document.getElementById('code-output');
    let dragging = false;
    let startY = 0;
    let startEditorHeight = 0;

    divider.addEventListener('mousedown', (e) => {
      dragging = true;
      startY = e.clientY;
      startEditorHeight = editorContainer.getBoundingClientRect().height;
      document.body.style.cursor = 'row-resize';
      document.body.style.userSelect = 'none';
    });
    window.addEventListener('mousemove', (e) => {
      if (!dragging) return;
      const dy = e.clientY - startY;
      let newH = startEditorHeight + dy;
      const minH = 200;
      const maxH = Math.max(minH, window.innerHeight - 220);
      newH = Math.max(minH, Math.min(maxH, newH));
      editorContainer.style.height = `${newH}px`;
      if (monacoEditor) monacoEditor.layout();
      window.dispatchEvent(new Event('split:resized'));
    });
    window.addEventListener('mouseup', () => {
      if (!dragging) return;
      dragging = false;
      document.body.style.cursor = '';
      document.body.style.userSelect = '';
    });
  })();

  // Mostra messaggio di benvenuto
  showOutput('Project editor loaded. Select a file from the tree or create a new one.', 'info');
}); 