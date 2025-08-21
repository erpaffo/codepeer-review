// Resizable split between left (editor) and right (terminal)
document.addEventListener('DOMContentLoaded', () => {
  const root = document.getElementById('run-shell-root');
  const left = document.getElementById('left-panel');
  const right = document.getElementById('right-panel');
  const divider = document.getElementById('drag-divider');
  const editorEl = document.getElementById('code-editor');
  const terminalEl = document.getElementById('terminal');

  if (!root || !left || !right || !divider) return;

  let isDragging = false;
  let startX = 0;
  let startLeftWidth = 0;

  const minWidth = 0; // allow full collapse if desired
  const maxWidth = () => {
    const total = root.getBoundingClientRect().width;
    return Math.max(minWidth, total - minWidth - divider.offsetWidth);
  };

  function onMouseDown(e) {
    isDragging = true;
    startX = e.clientX;
    startLeftWidth = left.getBoundingClientRect().width;
    document.body.style.cursor = 'col-resize';
    document.body.style.userSelect = 'none';
  }

  function onMouseMove(e) {
    if (!isDragging) return;
    const dx = e.clientX - startX;
    let newWidth = startLeftWidth + dx;
    newWidth = Math.max(minWidth, Math.min(maxWidth(), newWidth));
    // Use flex-basis to allow right panel to occupy remaining space
    left.style.flex = `0 0 ${newWidth}px`;
    left.style.width = `${newWidth}px`;
    right.style.flex = `1 1 ${root.getBoundingClientRect().width - newWidth - divider.offsetWidth}px`;

    // Trigger relayouts
    if (window.monaco && window.monaco.editor && editorEl && editorEl._monacoInstance) {
      try { editorEl._monacoInstance.layout(); } catch(e) {}
    }
    window.dispatchEvent(new Event('split:resized'));
  }

  function onMouseUp() {
    if (!isDragging) return;
    isDragging = false;
    document.body.style.cursor = '';
    document.body.style.userSelect = '';
    window.dispatchEvent(new Event('split:resized'));
  }

  divider.addEventListener('mousedown', onMouseDown);
  window.addEventListener('mousemove', onMouseMove);
  window.addEventListener('mouseup', onMouseUp);

  // Ensure layout on window resize
  window.addEventListener('resize', () => {
    window.dispatchEvent(new Event('split:resized'));
  });
});


