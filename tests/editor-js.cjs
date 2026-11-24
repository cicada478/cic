// Dependency-free event/model regression tests; this is not browser visual QA.
const fs = require('node:fs');
const vm = require('node:vm');
const assert = require('node:assert/strict');
class Element {
  constructor(tag = '') { this.tag = tag; this.children = []; this.dataset = {}; this.value = ''; }
  append(...children) { this.children.push(...children); }
  replaceChildren() { this.children = []; }
  setAttribute() {}
  focus() { focused = this; }
  scrollIntoView() {}
}
let focused;
const elements = Object.fromEntries(['cic-config','grid','undo','redo','add','status','error','code-panel',
  'done','cancel','csv','code','copy-code','r-code'].map(id => [id, new Element()]));
elements['cic-config'].textContent = JSON.stringify({output:'auto', columns:[
  {name:'T_cell', values:['CD3D','CD3E','TRAC']}, {name:'B_cell', values:['MS4A1']} ]});
function all(node) {return [node, ...node.children.flatMap(all)];}
const input = (c,r) => all(elements.grid).find(e => e.dataset.col === c && e.dataset.row === r);
const messages = [];
const shiny = {setInputValue: (id, payload) => messages.push(JSON.parse(JSON.stringify(payload))), addCustomMessageHandler() {}};
const context = {document:{getElementById:id=>elements[id], createElement:tag=>new Element(tag),
  querySelector(selector) { const [c,r] = [...selector.matchAll(/"(-?\d+)"/g)].map(m=>Number(m[1])); return input(c,r); }},
  window:{Shiny:shiny}, Shiny:shiny, navigator:{}, setTimeout, Blob, URL};
const path = process.argv[2] || 'inst/list-edit/editor.js';
vm.runInNewContext(fs.readFileSync(path, 'utf8'), context);
function key(c,r,key,more={}) {input(c,r).onkeydown({key,preventDefault(){},...more});}
function result() {elements.done.onclick(); return messages.at(-1).columns;}
key(0,1,'ArrowUp',{altKey:true});
assert.deepEqual(result().map(c=>c.values), [['CD3E','CD3D','TRAC'],['MS4A1']]);
elements.undo.onclick(); assert.equal(input(0,0).value,'CD3D');
elements.redo.onclick(); assert.equal(input(0,0).value,'CD3E');
input(0,3).onpaste({clipboardData:{getData:()=> '001\tLYZ\nNA\tLST1\n'},preventDefault(){}});
assert.deepEqual(result().map(c=>c.values), [['CD3E','CD3D','TRAC','001','NA'],['MS4A1','','','LYZ','LST1']]);
key(0,4,'Tab'); assert.equal(focused, input(1,4));
key(0,7,'Enter'); assert.equal(focused, input(0,8));
// Simulate actual registered drag/drop callbacks, including independent columns.
let sections = elements.grid.children;
sections[0].children[2].children[1].ondragstart({dataTransfer:{setData(){}}});
sections[0].children[4].ondrop({preventDefault(){},stopPropagation(){}});
assert.deepEqual(result()[0].values.slice(0,3), ['CD3D','TRAC','CD3E']);
sections = elements.grid.children;
sections[0].children[0].children[0].ondragstart({dataTransfer:{setData(){}}});
sections[1].children[0].ondrop({preventDefault(){},stopPropagation(){}});
assert.deepEqual(result().map(c=>c.name), ['B_cell','T_cell']);
elements.add.onclick(); assert.equal(result().length,3);
elements.undo.onclick(); assert.equal(result().length,2);
elements.cancel.onclick(); assert.equal(messages.at(-1).kind,'cancel');
console.log('PASS: independent reorder, drag/drop, undo/redo, paste, navigation, column reorder and cancel payload');
