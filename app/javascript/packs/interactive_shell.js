import consumer from "../channels/consumer"
import { Terminal } from "xterm"
import { FitAddon } from "xterm-addon-fit"
import 'xterm/css/xterm.css'

document.addEventListener('DOMContentLoaded', () => {
  const terminalContainer = document.getElementById('terminal');
  const loadingSpinner = document.getElementById('terminal-loading');
  if (!terminalContainer) return;
  const projectId = terminalContainer.dataset.projectId;
  if (!projectId) return;

  const PROMPT = '$ ';
  const HISTORY_KEY = `shell_history_${projectId}`;
  const MAX_HISTORY_SIZE = 1000;

  // Mostra spinner, nascondi terminale
  terminalContainer.style.display = 'none';
  if (loadingSpinner) loadingSpinner.style.display = 'flex';

  const term = new Terminal({
    cursorBlink: true,
    fontFamily: 'monospace',
    theme: { 
      background: '#1e1e1e',
      foreground: '#ffffff',
      cursor: '#ffffff',
      selection: '#264f78',
      black: '#000000',
      red: '#cd3131',
      green: '#0dbc79',
      yellow: '#e5e510',
      blue: '#2472c8',
      magenta: '#bc3fbc',
      cyan: '#11a8cd',
      white: '#e5e5e5',
      brightBlack: '#666666',
      brightRed: '#f14c4c',
      brightGreen: '#23d18b',
      brightYellow: '#f5f543',
      brightBlue: '#3b8eea',
      brightMagenta: '#d670d6',
      brightCyan: '#29b8db',
      brightWhite: '#ffffff'
    },
    rows: 30,
    cols: 80,
    allowTransparency: true,
    convertEol: true,
    scrollback: 1000
  });

  const fitAddon = new FitAddon();
  term.loadAddon(fitAddon);

  // Funzione per aggiornare il messaggio di caricamento
  function updateLoadingMessage(message) {
    if (loadingSpinner) {
      const messageElement = loadingSpinner.querySelector('span');
      if (messageElement) {
        messageElement.textContent = message;
      }
    }
  }

  // Funzione per inizializzare il terminale
  async function initializeTerminal() {
    updateLoadingMessage('Connecting to shell...');
    updateTerminalStatus('connecting', 'Connecting...');
    
    // Aspetta un momento per permettere al server di inizializzare il container
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Mostra il terminale direttamente
    if (loadingSpinner) loadingSpinner.style.display = 'none';
    terminalContainer.style.display = 'flex';
    terminalContainer.style.flexDirection = 'column';
    term.open(terminalContainer);
    fitAddon.fit();
    term.write('Welcome to CodePeer Terminal!\r\n');
    term.write('Type "help" for available commands.\r\n');
    term.write('Connected to shell...\r\n' + PROMPT);
    updateTerminalStatus('connected', 'Connected');
    
    // Test automatico del container dopo 3 secondi
    setTimeout(() => {
      shellChannel.sendInput('docker-status');
    }, 3000);
  }

  // Funzione per aggiornare lo stato del terminale
  function updateTerminalStatus(status, text) {
    const statusIndicator = document.getElementById('terminal-status');
    const statusText = document.getElementById('terminal-status-text');
    
    if (statusIndicator && statusText) {
      statusIndicator.className = `status-indicator ${status}`;
      statusText.textContent = text;
    }
  }

  // Funzione per aggiornare la directory corrente
  function updateCurrentPWD(path) {
    const pwdElement = document.getElementById('current-pwd');
    if (pwdElement) {
      pwdElement.textContent = path;
    }
  }

  // Avvia l'inizializzazione del terminale
  initializeTerminal();

  // Refitting when split resizes
  window.addEventListener('split:resized', () => {
    try { fitAddon.fit(); } catch(e) {}
  });

  let currentCommand = '';
  let commandHistory = loadHistory();
  let historyIndex = -1;
  let cursorPosition = 0;
  let isSearching = false;
  let searchQuery = '';
  let searchResults = [];
  let currentSearchIndex = -1;
  let tempCurrent = ''; // Variabile per salvare il comando corrente durante la navigazione

  // Funzione per caricare la cronologia dal localStorage
  function loadHistory() {
    try {
      const saved = localStorage.getItem(HISTORY_KEY);
      return saved ? JSON.parse(saved) : [];
    } catch (error) {
      console.warn('Failed to load command history:', error);
      return [];
    }
  }

  // Funzione per salvare la cronologia nel localStorage
  function saveHistory() {
    try {
      // Mantieni solo gli ultimi MAX_HISTORY_SIZE comandi
      const historyToSave = commandHistory.slice(-MAX_HISTORY_SIZE);
      localStorage.setItem(HISTORY_KEY, JSON.stringify(historyToSave));
    } catch (error) {
      console.warn('Failed to save command history:', error);
    }
  }

  // Funzione per aggiungere un comando alla cronologia
  function addToHistory(command) {
    // Rimuovi duplicati consecutivi
    if (commandHistory.length === 0 || commandHistory[commandHistory.length - 1] !== command) {
      commandHistory.push(command);
      saveHistory();
    }
  }

  // Comandi disponibili per l'autocompletamento
  const availableCommands = [
    'ls', 'cd', 'pwd', 'cat', 'cp', 'mv', 'rm', 'mkdir', 'rmdir', 'touch',
    'grep', 'find', 'chmod', 'chown', 'ps', 'top', 'kill', 'nano', 'vim',
    'python3', 'python', 'node', 'npm', 'git', 'gcc', 'g++', 'make',
    'echo', 'export', 'source', 'alias', 'unalias', 'history', 'clear',
    'head', 'tail', 'less', 'more', 'wc', 'sort', 'uniq', 'cut', 'sed', 'awk',
    'curl', 'wget', 'tar', 'gzip', 'gunzip', 'zip', 'unzip',
    'whoami', 'id', 'groups', 'date', 'cal', 'uptime', 'free', 'df', 'du',
    'ping', 'traceroute', 'netstat', 'ss', 'htop', 'tree', 'tmux', 'screen'
  ];

  // Funzione per ottenere i file nella directory corrente
  async function getFilesInCurrentDirectory() {
    return new Promise((resolve) => {
      const tempChannel = consumer.subscriptions.create(
        { channel: 'ShellChannel', project_id: projectId },
        {
          received(data) {
            if (data.output) {
              const files = data.output.trim().split('\n').filter(line => line.trim());
              resolve(files);
            }
            this.unsubscribe();
          }
        }
      );
      tempChannel.perform('send_input', { input: 'ls -1' });
    });
  }

  // Funzione per autocompletamento
  async function handleTabCompletion() {
    const words = currentCommand.split(' ');
    const currentWord = words[words.length - 1] || '';
    
    if (currentWord.startsWith('./') || currentWord.startsWith('/')) {
      // Completamento file/directory
      try {
        const files = await getFilesInCurrentDirectory();
        const matches = files.filter(file => 
          file.startsWith(currentWord.replace('./', ''))
        );
        
        if (matches.length === 1) {
          // Completamento unico
          words[words.length - 1] = currentWord.startsWith('./') ? 
            './' + matches[0] : '/' + matches[0];
          currentCommand = words.join(' ');
          cursorPosition = currentCommand.length;
          
          // Cancella riga e riscrivi
          term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
          term.write(currentCommand);
        } else if (matches.length > 1) {
          // Mostra opzioni
          term.write('\r\n');
          matches.forEach(match => term.write(match + '  '));
          term.write('\r\n' + PROMPT + currentCommand);
        }
      } catch (error) {
        // Fallback al completamento comandi
        const matches = availableCommands.filter(cmd => 
          cmd.startsWith(currentWord)
        );
        if (matches.length === 1) {
          words[words.length - 1] = matches[0];
          currentCommand = words.join(' ');
          cursorPosition = currentCommand.length;
          
          term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
          term.write(currentCommand);
        }
      }
    } else {
      // Completamento comandi
      const matches = availableCommands.filter(cmd => 
        cmd.startsWith(currentWord)
      );
      
      if (matches.length === 1) {
        words[words.length - 1] = matches[0];
        currentCommand = words.join(' ');
        cursorPosition = currentCommand.length;
        
        term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
        term.write(currentCommand);
      } else if (matches.length > 1) {
        term.write('\r\n');
        matches.forEach(match => term.write(match + '  '));
        term.write('\r\n' + PROMPT + currentCommand);
      }
    }
  }

  // Funzione per ricerca nella cronologia
  function startHistorySearch() {
    isSearching = true;
    searchQuery = '';
    searchResults = [];
    currentSearchIndex = -1;
    term.write('\r\n(reverse-i-search)`\': ');
  }

  function handleHistorySearch(char) {
    if (char === '\r') { // Enter
      if (searchResults.length > 0 && currentSearchIndex >= 0) {
        currentCommand = searchResults[currentSearchIndex];
        cursorPosition = currentCommand.length;
        isSearching = false;
        term.write('\r\n' + PROMPT + currentCommand);
      } else {
        isSearching = false;
        term.write('\r\n' + PROMPT);
      }
      return;
    }
    
    if (char === '\x1b') { // Escape
      isSearching = false;
      term.write('\r\n' + PROMPT + currentCommand);
      return;
    }
    
    if (char === '\x7f') { // Backspace
      if (searchQuery.length > 0) {
        searchQuery = searchQuery.slice(0, -1);
        term.write('\b \b');
      }
    } else if (char >= ' ') {
      searchQuery += char;
      term.write(char);
    }
    
    // Filtra la cronologia
    searchResults = commandHistory.filter(cmd => 
      cmd.toLowerCase().includes(searchQuery.toLowerCase())
    );
    currentSearchIndex = searchResults.length - 1;
  }

  // Funzione per cancellare parola
  function deleteWord() {
    const beforeCursor = currentCommand.slice(0, cursorPosition);
    const afterCursor = currentCommand.slice(cursorPosition);
    
    const words = beforeCursor.split(' ');
    if (words.length > 1) {
      words.pop();
      const newBeforeCursor = words.join(' ');
      currentCommand = newBeforeCursor + afterCursor;
      const newCursorPosition = newBeforeCursor.length;
      
      // Cancella dalla posizione del cursore alla fine della parola
      term.write('\b'.repeat(cursorPosition - newCursorPosition) + 
                 ' '.repeat(cursorPosition - newCursorPosition) + 
                 '\b'.repeat(cursorPosition - newCursorPosition));
      cursorPosition = newCursorPosition;
    }
  }

  // Funzione per cancellare tutto prima del cursore
  function deleteLineBeforeCursor() {
    const afterCursor = currentCommand.slice(cursorPosition);
    currentCommand = afterCursor;
    
    // Cancella tutto prima del cursore
    term.write('\r' + PROMPT + ' '.repeat(cursorPosition) + '\r' + PROMPT);
    cursorPosition = 0;
    term.write(afterCursor);
  }

  // Funzione per pulire lo schermo
  function clearScreen() {
    term.clear();
    term.write(PROMPT);
  }

  // Funzione per gestire l'output colorato
  function writeColoredOutput(output) {
    // xterm.js gestisce automaticamente i codici ANSI per i colori
    term.write(output);
  }

  const shellChannel = consumer.subscriptions.create(
    { channel: 'ShellChannel', project_id: projectId },
    {
      connected() {
        console.log(`Connected to ShellChannel for project ID: ${projectId}`);
        // Aggiorna lo stato quando il canale si connette
        updateTerminalStatus('connected', 'Connected');
      },
      disconnected() {
        console.log(`Disconnected from ShellChannel for project ID: ${projectId}`);
        term.write('\r\nDisconnected from shell.\r\n');
        updateTerminalStatus('disconnected', 'Disconnected');
      },
      rejected() {
        console.error(`ShellChannel subscription rejected for project ID: ${projectId}`);
        term.write('\r\nFailed to connect to shell.\r\n');
        updateTerminalStatus('disconnected', 'Connection failed');
      },
      received(data) {
        console.log('Received data from ShellChannel:', data);
        
        if (data.output) {
          // Controlla se l'output contiene un comando cd
          const output = data.output.trim();
          if (output && !output.includes('\n') && !output.includes('Error') && !output.includes('⚠️') && !output.includes('💡')) {
            // Potrebbe essere il risultato di un cd
            if (output.startsWith('/') || output.includes('/app')) {
              updateCurrentPWD(output);
            }
          }
          writeColoredOutput(data.output);
        }
        if (data.error) {
          term.write(`\r\nError: ${data.error}\r\n`);
        }
        // Aggiungi prompt solo se l'output non termina già con un prompt
        const output = data.output || '';
        if (!output.trim().endsWith('$') && !output.trim().endsWith('#')) {
          term.write('\r\n' + PROMPT);
        }
      },
      sendInput(input) {
        this.perform('send_input', { input });
      }
    }
  );

  // Gestione input del terminale
  term.onData((data) => {
    if (isSearching) {
      handleHistorySearch(data);
      return;
    }

    // Gestione sequenze di escape per le frecce direzionali
    if (data.startsWith('\x1b[')) {
      const code = data.slice(2);
      if (code === 'A') { // Up arrow
        if (commandHistory.length === 0) return;
        if (historyIndex > 0) {
          if (historyIndex === commandHistory.length) {
            tempCurrent = currentCommand;
          }
          historyIndex--;
          term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
          currentCommand = commandHistory[historyIndex];
          cursorPosition = currentCommand.length;
          term.write(currentCommand);
        }
        return;
      } else if (code === 'B') { // Down arrow
        if (commandHistory.length === 0) return;
        if (historyIndex < commandHistory.length - 1) {
          historyIndex++;
          term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
          currentCommand = commandHistory[historyIndex];
          cursorPosition = currentCommand.length;
          term.write(currentCommand);
        } else if (historyIndex === commandHistory.length - 1) {
          historyIndex++;
          term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
          currentCommand = tempCurrent || '';
          cursorPosition = currentCommand.length;
          term.write(currentCommand);
        }
        return;
      } else if (code === 'C') { // Right arrow
        if (cursorPosition < currentCommand.length) {
          cursorPosition++;
          term.write(currentCommand[cursorPosition - 1]);
        }
        historyIndex = commandHistory.length;
        return;
      } else if (code === 'D') { // Left arrow
        if (cursorPosition > 0) {
          cursorPosition--;
          term.write('\b');
        }
        historyIndex = commandHistory.length;
        return;
      }
    }

    const code = data.charCodeAt(0);

    if (code === 13) { // Enter
      if (currentCommand.trim() === 'clear') {
        // Cancella la riga corrente (prompt + comando)
        term.write('\r' + ' '.repeat(PROMPT.length + currentCommand.length) + '\r');
        clearScreen();
        currentCommand = '';
        cursorPosition = 0;
        historyIndex = commandHistory.length;
        return;
      }
      if (currentCommand.trim()) {
        addToHistory(currentCommand);
        historyIndex = commandHistory.length;
        shellChannel.sendInput(currentCommand);
        term.write('\r\n');
        currentCommand = '';
        cursorPosition = 0;
      } else {
        term.write('\r\n' + PROMPT);
        historyIndex = commandHistory.length;
      }
    } else if (code === 8 || code === 127) { // Backspace o DEL
      if (currentCommand.length > 0 && cursorPosition > 0) {
        const beforeCursor = currentCommand.slice(0, cursorPosition - 1);
        const afterCursor = currentCommand.slice(cursorPosition);
        currentCommand = beforeCursor + afterCursor;
        cursorPosition--;
        term.write('\b \b');
        if (afterCursor.length > 0) {
          term.write(afterCursor + ' \b'.repeat(afterCursor.length + 1));
        }
      }
      historyIndex = commandHistory.length;
    } else if (code === 9) { // Tab
      handleTabCompletion();
    } else if (data === '\x03') { // Ctrl+C
      term.write('^C\r\n' + PROMPT);
      currentCommand = '';
      cursorPosition = 0;
      historyIndex = commandHistory.length;
    } else if (data === '\x0c') { // Ctrl+L
      clearScreen();
    } else if (data === '\x17') { // Ctrl+W
      deleteWord();
      historyIndex = commandHistory.length;
    } else if (data === '\x15') { // Ctrl+U
      deleteLineBeforeCursor();
      historyIndex = commandHistory.length;
    } else if (data === '\x12') { // Ctrl+R
      startHistorySearch();
    } else if (data === '\x01') { // Ctrl+A (Home)
      term.write('\r' + PROMPT);
      cursorPosition = 0;
      historyIndex = commandHistory.length;
    } else if (data === '\x05') { // Ctrl+E (End)
      const remaining = currentCommand.slice(cursorPosition);
      term.write(remaining);
      cursorPosition = currentCommand.length;
      historyIndex = commandHistory.length;
    } else if (code >= 32) { // Caratteri stampabili
      const beforeCursor = currentCommand.slice(0, cursorPosition);
      const afterCursor = currentCommand.slice(cursorPosition);
      currentCommand = beforeCursor + data + afterCursor;
      cursorPosition++;
      term.write(data);
      if (afterCursor.length > 0) {
        term.write(afterCursor + '\b'.repeat(afterCursor.length));
      }
      historyIndex = commandHistory.length;
    }
  });

  // Ridimensiona il terminale quando la finestra cambia dimensione
  window.addEventListener('resize', () => {
    fitAddon.fit();
  });

  // Salva la cronologia quando la pagina viene chiusa
  window.addEventListener('beforeunload', () => {
    saveHistory();
  });
}); 