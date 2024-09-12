document.addEventListener('DOMContentLoaded', () => {
    const logOutput = document.getElementById('log-output');
  
    function fetchLogs() {
      fetch(window.location.href)
        .then(response => response.text())
        .then(html => {
          const parser = new DOMParser();
          const doc = parser.parseFromString(html, 'text/html');
          const newLogs = doc.getElementById('log-output').innerHTML;
  
          logOutput.innerHTML = newLogs;
          logOutput.scrollTop = logOutput.scrollHeight;
        })
        .catch(error => console.error('Error fetching logs:', error));
    }
  
    setInterval(fetchLogs, 3000); // Poll every 3 seconds
  });

  document.addEventListener('turbo:load', function() {
    document.getElementById('run-project-btn').addEventListener('click', function() {
      this.disabled = true;
      this.innerText = 'Running...';
    });
  });
  
  