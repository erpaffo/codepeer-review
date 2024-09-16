import { Terminal } from 'xterm';
import { FitAddon } from 'xterm-addon-fit';
import consumer from "../channels/consumer";

document.addEventListener('DOMContentLoaded', () => {
  const terminalContainer = document.getElementById('terminal');

  if (!terminalContainer) {
    console.warn('Terminal container not found. Skipping ShellChannel subscription.');
    return;
  }

  const projectId = terminalContainer.dataset.projectId;

  if (!projectId) {
    console.error('Project ID is missing. Cannot subscribe to ShellChannel.');
    return;
  }

  console.log(`Initializing terminal for project ID: ${projectId}`);

  const term = new Terminal({
    cursorBlink: true,
    fontFamily: 'monospace',  // Usa un font monospace per garantire l'allineamento
    theme: {
      background: '#1e1e1e',
    },
  });

  const fitAddon = new FitAddon();
  term.loadAddon(fitAddon);
  term.open(terminalContainer);
  fitAddon.fit();

  const outputBuffer = [];

  // Recupera il campo di input e il bottone
  const commandInput = document.getElementById('command-input');
  const executeButton = document.getElementById('execute-command');

  // Connessione a ShellChannel
  const shellChannel = consumer.subscriptions.create(
    { channel: 'ShellChannel', project_id: projectId },
    {
      connected() {
        console.log(`Connected to ShellChannel for project ID: ${projectId}`);
      },

      disconnected() {
        console.log(`Disconnected from ShellChannel for project ID: ${projectId}`);
      },

      received(data) {
        if (data.output) {
          // Aggiungi output al buffer e scrivi tutto insieme
          outputBuffer.push(data.output.replace(/\n/g, '\r\n'));
          term.write(outputBuffer.join('')); // Scrive il buffer
          outputBuffer.length = 0; // Svuota il buffer
          console.log(`Received output: ${data.output}`);
        }
        if (data.error) {
          term.write(`\r\nError: ${data.error}\r\n`);
          console.log(`Received error: ${data.error}`);
        }
      },

      sendInput(input) {
        console.log(`Sending input to ShellChannel: ${input}`);
        this.perform('send_input', { input: input });
      }
    }
  );

  // Gestione del click sul bottone per eseguire il comando
  executeButton.addEventListener('click', () => {
    const command = commandInput.value.trim();
    if (command) {
      shellChannel.sendInput(command);
      term.write(`\r\n$ ${command}\r\n`); // Visualizza il comando nel terminale
      commandInput.value = '';
    }
  });

  // Gestione dell'invio del comando premendo Invio nel campo di input
  commandInput.addEventListener('keydown', (event) => {
    if (event.key === 'Enter') {
      event.preventDefault();
      executeButton.click();
    }
  });

  // Ridimensiona il terminale quando la finestra cambia dimensione
  window.addEventListener('resize', () => {
    fitAddon.fit();
  });
});
