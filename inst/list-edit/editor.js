/* Independent-column editor. DataEditR inspired the workflow, not this code. */
(() => {
  'use strict';
  const config = JSON.parse(document.getElementById('cic-config').textContent);
  let cols = config.columns.map(c => ({name: c.name, values: Array.isArray(c.values) ? c.values : [c.values]}));
  let past = [], future = [], drag = null;
  const $ = id => document.getElementById(id);
  const snapshot = () => JSON.stringify(cols);
  function save() { past.push(snapshot()); if (past.length > 100) past.shift(); future = []; }
  function button(text, label, run) {
    const b = document.createElement('button'); b.textContent = text;
    b.title = label; b.setAttribute('aria-label', label); b.onclick = run; return b;
  }
  function focus(c, r) {
    const el = document.querySelector(`[data-col="${c}"][data-row="${r}"]`);
    if (el) { el.focus(); el.scrollIntoView({block: 'nearest', inline: 'nearest'}); }
  }
  function moveColumn(from, to) {
    if (to < 0 || to >= cols.length || from === to) return;
    save(); cols.splice(to, 0, cols.splice(from, 1)[0]); render(); focus(to, -1);
  }
  function moveItem(c, from, to) {
    const v = cols[c].values;
    if (from === to || from >= v.length || to < 0 || to >= v.length) return;
    save(); v.splice(to, 0, v.splice(from, 1)[0]); render(); focus(c, to);
  }
  function handle(kind, c, r) {
    const h = document.createElement('span'); h.textContent = '⋮⋮'; h.className = 'handle';
    h.draggable = true; h.title = kind === 'column' ? 'Drag column' : 'Drag item within this column';
    h.ondragstart = e => { drag = {kind, c, r}; e.dataTransfer.setData('text/plain', kind); e.dataTransfer.effectAllowed = 'move'; };
    h.ondragend = () => { drag = null; }; return h;
  }
  function target(el, kind, c, r) {
    el.ondragover = e => { if (drag && drag.kind === kind && (kind === 'column' || drag.c === c)) e.preventDefault(); };
    el.ondrop = e => {
      e.preventDefault(); e.stopPropagation(); if (!drag || drag.kind !== kind) return;
      if (kind === 'column') moveColumn(drag.c, c);
      else if (drag.c === c) moveItem(c, drag.r, Math.min(r, cols[c].values.length - 1));
      drag = null;
    };
  }
  function render() {
    $('grid').replaceChildren();
    const rows = Math.max(8, ...cols.map(c => c.values.length + 1));
    cols.forEach((col, c) => {
      const section = document.createElement('section'); section.className = 'list-column';
      const head = document.createElement('div'); head.className = 'column-head';
      head.append(handle('column', c, -1)); target(head, 'column', c, -1);
      const name = document.createElement('input'); name.value = col.name;
      name.dataset.col = c; name.dataset.row = -1; name.setAttribute('aria-label', `Column ${c + 1} name`);
      name.oninput = () => { save(); col.name = name.value; update(); };
      name.onkeydown = e => { if(e.key === 'Enter') {e.preventDefault(); focus(c, 0);} };
      head.append(name); section.append(head);
      const tools = document.createElement('div'); tools.className = 'column-tools';
      const left = button('←', 'Move column left', () => moveColumn(c, c - 1)); left.disabled = c === 0;
      const right = button('→', 'Move column right', () => moveColumn(c, c + 1)); right.disabled = c === cols.length - 1;
      tools.append(left, right, button('Delete', 'Delete column (Undo to restore)', () => {
        if(cols.length === 1) { $('error').textContent = 'Keep at least one column.'; return; }
        save(); cols.splice(c, 1); render();
      })); section.append(tools);
      for(let r = 0; r < rows; r++) {
        const row = document.createElement('div'); row.className = 'cell'; target(row, 'item', c, r);
        const idx = document.createElement('span'); idx.className = 'index'; idx.textContent = r + 1;
        const input = document.createElement('input'); input.value = col.values[r] || '';
        input.dataset.col = c; input.dataset.row = r;
        input.setAttribute('aria-label', `${col.name}, item ${r + 1}`);
        input.oninput = () => {
          save(); while(col.values.length <= r) col.values.push(''); col.values[r] = input.value; update();
        };
        input.onkeydown = e => {
          if(e.key === 'Escape') { $('add').focus(); return; }
          if(e.altKey && ['ArrowUp','ArrowDown'].includes(e.key)) {
            e.preventDefault(); moveItem(c, r, r + (e.key === 'ArrowUp' ? -1 : 1)); return;
          }
          if(e.key === 'Enter' || e.key === 'Tab') {
            e.preventDefault(); let nc = c, nr = r;
            if(e.key === 'Enter') nr += e.shiftKey ? -1 : 1;
            else { nc += e.shiftKey ? -1 : 1; if(nc === cols.length) {nc = 0; nr++;} if(nc < 0) {nc = cols.length - 1; nr--;} }
            if(nr < 0) { focus(nc, -1); return; }
            if(nr >= rows) { save(); while(cols[nc].values.length < nr) cols[nc].values.push(''); }
            render(); focus(nc, nr);
          }
        };
        input.onpaste = e => {
          const text = e.clipboardData.getData('text/plain');
          if(!/[\t\r\n]/.test(text)) return;
          e.preventDefault(); const lines = text.replace(/\r\n?/g, '\n').replace(/\n$/, '').split('\n').map(l => l.split('\t'));
          if(config.output === 'vector' && lines.some(l => l.length > 1)) { $('error').textContent = 'Vector mode accepts one column only.'; return; }
          save(); lines.forEach((cells, dr) => cells.forEach((v, dc) => {
            while(cols.length <= c + dc) cols.push({name: newName(), values: []});
            const dest = cols[c + dc].values; while(dest.length <= r + dr) dest.push(''); dest[r + dr] = v;
          })); render(); focus(c, r);
        };
        row.append(idx, handle('item', c, r), input);
        const up = button('↑', 'Move item up', () => moveItem(c, r, r - 1)); up.disabled = r === 0 || r >= col.values.length;
        const down = button('↓', 'Move item down', () => moveItem(c, r, r + 1)); down.disabled = r >= col.values.length - 1;
        row.append(up, down); section.append(row);
      }
      $('grid').append(section);
    }); update();
  }
  function newName() { let i = 1; while(cols.some(c => c.name === `list${i}`)) i++; return `list${i}`; }
  function update() {
    $('undo').disabled = !past.length; $('redo').disabled = !future.length;
    $('add').disabled = config.output === 'vector';
    $('status').textContent = `${cols.length} column(s) · ${cols.reduce((n,c) => n + c.values.filter(v => v.trim()).length, 0)} items · Text only; blank cells omitted`;
    $('error').textContent = ''; $('code-panel').hidden = true;
  }
  $('add').onclick = () => {save(); cols.push({name: newName(), values: []}); render(); focus(cols.length - 1, -1);};
  $('undo').onclick = () => {if(past.length) {future.push(snapshot()); cols = JSON.parse(past.pop()); render();}};
  $('redo').onclick = () => {if(future.length) {past.push(snapshot()); cols = JSON.parse(future.pop()); render();}};
  function send(kind) {
    if(!window.Shiny || !Shiny.setInputValue) { $('error').textContent = 'Waiting for the R connection.'; return; }
    Shiny.setInputValue('edit_action', {kind, columns: cols}, {priority: 'event'});
  }
  ['done','cancel','csv','code'].forEach(id => {$(id).onclick = () => send(id);});
  $('copy-code').onclick = async () => {
    $('r-code').select();
    try { await navigator.clipboard.writeText($('r-code').value); }
    catch (_) { $('error').textContent = 'Code selected. Press Ctrl+C to copy.'; }
  };
  function register() {
    Shiny.addCustomMessageHandler('cic-error', message => {$('error').textContent = message;});
    Shiny.addCustomMessageHandler('cic-code', code => {$('r-code').value = code; $('code-panel').hidden = false;});
    Shiny.addCustomMessageHandler('cic-csv', csv => {
      const url = URL.createObjectURL(new Blob(['\uFEFF', csv], {type: 'text/csv;charset=utf-8'}));
      const a = document.createElement('a'); a.href = url; a.download = 'lists.csv'; a.click(); setTimeout(() => URL.revokeObjectURL(url), 1000);
    });
  }
  register(); render();
})();
