import consumer from "../channels/consumer"
import { Terminal } from "xterm"
import { FitAddon } from "xterm-addon-fit"

document.addEventListener('DOMContentLoaded', () => {
  const terminalContainer = document.getElementById('terminal');
  const loadingSpinner = document.getElementById('terminal-loading');
  if (!terminalContainer) return;
  const projectId = terminalContainer.dataset.projectId;
  if (!projectId) return;
  // Mostra spinner, nascondi terminale
  terminalContainer.style.display = 'none';
  if (loadingSpinner) loadingSpinner.style.display = 'flex';
  const term = new Terminal({
    cursorBlink: true,
    fontFamily: 'monospace',
    theme: { background: '#1e1e1e' },
  });
  const fitAddon = new FitAddon();
  term.loadAddon(fitAddon);
  // Quando il terminale è pronto, mostra terminale e nascondi spinner
  setTimeout(() => {
    if (loadingSpinner) loadingSpinner.style.display = 'none';
    terminalContainer.style.display = '';
    term.open(terminalContainer);
    fitAddon.fit();
  }, 100); // piccolo delay per UX
  const outputBuffer = [];
  const commandInput = document.getElementById('command-input');
  const executeButton = document.getElementById('execute-command');
  const shellChannel = consumer.subscriptions.create(
    { channel: 'ShellChannel', project_id: projectId },
    {
      connected() { console.log(`Connected to ShellChannel for project ID: ${projectId}`); },
      disconnected() { console.log(`Disconnected from ShellChannel for project ID: ${projectId}`); },
      received(data) {
        if (data.output) {
          outputBuffer.push(data.output.replace(/\n/g, '\r\n'));
          term.write(outputBuffer.join(''));
          outputBuffer.length = 0;
        }
        if (data.error) {
          term.write(`\r\nError: ${data.error}\r\n`);
        }
      },
      sendInput(input) { this.perform('send_input', { input }); }
    }
  );
  executeButton.addEventListener('click', () => {
    const command = commandInput.value.trim();
    if (command) {
      shellChannel.sendInput(command);
      term.write(`\r\n$ ${command}\r\n`);
      commandInput.value = '';
    }
  });
  commandInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      executeButton.click();
    }
  });
  window.addEventListener('resize', () => { fitAddon.fit(); });
}); 