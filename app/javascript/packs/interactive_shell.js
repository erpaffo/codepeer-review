import consumer from "../channels/consumer"
import { Terminal } from "xterm"
import { FitAddon } from "xterm-addon-fit"

document.addEventListener('DOMContentLoaded', () => {
  const terminalContainer = document.getElementById('terminal');
  const loadingSpinner = document.getElementById('terminal-loading');
  if (!terminalContainer) return;
  const projectId = terminalContainer.dataset.projectId;
  if (!projectId) return;

  const PROMPT = '$ ';

  // Mostra spinner, nascondi terminale
  terminalContainer.style.display = 'none';
  if (loadingSpinner) loadingSpinner.style.display = 'flex';

  const term = new Terminal({
    cursorBlink: true,
    fontFamily: 'monospace',
    theme: { background: '#1e1e1e' },
    rows: 30,
    cols: 80
  });

  const fitAddon = new FitAddon();
  term.loadAddon(fitAddon);

  // Quando il terminale è pronto, mostra terminale e nascondi spinner
  setTimeout(() => {
    if (loadingSpinner) loadingSpinner.style.display = 'none';
    terminalContainer.style.display = '';
    term.open(terminalContainer);
    fitAddon.fit();
    // Mostra prompt iniziale
    term.write('\r\n' + PROMPT);
  }, 100);

  let currentCommand = '';
  let commandHistory = [];
  let historyIndex = -1;

  const shellChannel = consumer.subscriptions.create(
    { channel: 'ShellChannel', project_id: projectId },
    {
      connected() {
        console.log(`Connected to ShellChannel for project ID: ${projectId}`);
        term.write('Connected to shell...\r\n');
      },
      disconnected() {
        console.log(`Disconnected from ShellChannel for project ID: ${projectId}`);
        term.write('\r\nDisconnected from shell.\r\n');
      },
      received(data) {
        if (data.output) {
          term.write(data.output);
        }
        if (data.error) {
          term.write(`\r\nError: ${data.error}\r\n`);
        }
        // Mostra nuovo prompt dopo l'output
        term.write('\r\n' + PROMPT);
      },
      sendInput(input) {
        this.perform('send_input', { input });
      }
    }
  );

  // Gestione input del terminale
  term.onData((data) => {
    const code = data.charCodeAt(0);

    if (code === 13) { // Enter
      if (currentCommand.trim()) {
        // Aggiungi comando alla cronologia
        commandHistory.push(currentCommand);
        historyIndex = commandHistory.length;

        // Invia comando al server
        shellChannel.sendInput(currentCommand);
        term.write('\r\n');
        currentCommand = '';
      } else {
        term.write('\r\n' + PROMPT);
      }
    } else if (code === 8 || code === 127) { // Backspace o DEL
      if (currentCommand.length > 0) {
        currentCommand = currentCommand.slice(0, -1);
        term.write('\b \b');
      }
      // NON permettere di cancellare il prompt
    } else if (code === 38) { // Up arrow
      if (historyIndex > 0) {
        historyIndex--;
        // Cancella riga corrente
        term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
        currentCommand = commandHistory[historyIndex];
        term.write(currentCommand);
      }
    } else if (code === 40) { // Down arrow
      if (historyIndex < commandHistory.length - 1) {
        historyIndex++;
        // Cancella riga corrente
        term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
        currentCommand = commandHistory[historyIndex];
        term.write(currentCommand);
      } else if (historyIndex === commandHistory.length - 1) {
        historyIndex++;
        // Cancella riga corrente
        term.write('\r' + PROMPT + ' '.repeat(currentCommand.length) + '\r' + PROMPT);
        currentCommand = '';
      }
    } else if (code >= 32) { // Caratteri stampabili
      currentCommand += data;
      term.write(data);
    }
  });

  // Ridimensiona il terminale quando la finestra cambia dimensione
  window.addEventListener('resize', () => {
    fitAddon.fit();
  });
}); 