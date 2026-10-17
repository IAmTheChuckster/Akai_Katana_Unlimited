import json, os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
patch = json.load(open(sys.argv[1]))  # [[offset, base64], ...] from tools/web/diff.py
mra = open(os.path.join(HERE, 'mra_template.xml')).read()
html = r'''<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Akai Katana Gold Patcher</title>
<style>
  :root {
    --bg: #fbf6f2;
    --panel: #ffffff;
    --ink: #2a1a16;
    --muted: #7a645c;
    --line: #ecd8cc;
    --accent: #c62d1f;
    --accent-ink: #ffffff;
    --gold: #b8860b;
    --ok: #1f8a4c;
    --bad: #c62828;
    --warn: #b26a00;
    --code: #f7ebe3;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #161110;
      --panel: #211917;
      --ink: #f4e9e3;
      --muted: #bba69c;
      --line: #3e2e29;
      --accent: #ff5a47;
      --accent-ink: #161110;
      --gold: #f0c050;
      --ok: #5fd08f;
      --bad: #ff7b7b;
      --warn: #ffb44d;
      --code: #2c211e;
    }
  }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--ink);
    font: 16px/1.55 system-ui, -apple-system, "Segoe UI", Roboto, "Hiragino Sans", sans-serif;
  }
  main { max-width: 760px; margin: 0 auto; padding: 32px 16px 64px; }
  h1 { font-size: 1.7rem; margin: 0 0 4px; letter-spacing: .01em; }
  h1 span { color: var(--gold); }
  .lead { color: var(--muted); margin: 0 0 28px; }
  section {
    background: var(--panel);
    border: 1px solid var(--line);
    border-radius: 14px;
    padding: 20px;
    margin-bottom: 18px;
  }
  h2 { font-size: 1.05rem; margin: 0 0 12px; }
  h2 b {
    display: inline-flex; align-items: center; justify-content: center;
    width: 1.6em; height: 1.6em; margin-right: .5em;
    border-radius: 50%; background: var(--accent); color: var(--accent-ink); font-size: .85em;
  }
  #drop {
    display: block;
    border: 2px dashed var(--line);
    border-radius: 12px;
    padding: 28px 16px;
    text-align: center;
    cursor: pointer;
    transition: border-color .15s, background .15s;
  }
  #drop.over, #drop:hover { border-color: var(--accent); background: var(--code); }
  #drop * { pointer-events: none; }
  body.dragging #drop { border-color: var(--accent); background: var(--code); }
  #drop p { margin: 4px 0; }
  #drop small { color: var(--muted); }
  input[type=file] { display: none; }
  .scroll { overflow-x: auto; }
  table { width: 100%; border-collapse: collapse; font-size: .92rem; }
  th, td { text-align: left; padding: 7px 8px; border-bottom: 1px solid var(--line); }
  th { color: var(--muted); font-weight: 600; }
  td code, p code, li code { background: var(--code); padding: 1px 5px; border-radius: 5px; font-size: .9em; }
  .ok { color: var(--ok); font-weight: 600; }
  .bad { color: var(--bad); font-weight: 600; }
  .warn { color: var(--warn); font-weight: 600; }
  .wait { color: var(--muted); }
  #msg { margin: 12px 0 0; }
  .btns { display: flex; flex-wrap: wrap; gap: 10px; }
  .btn {
    display: inline-block;
    padding: 10px 16px;
    border-radius: 10px;
    background: var(--accent);
    color: var(--accent-ink);
    text-decoration: none;
    font-weight: 600;
    border: 0;
  }
  .btn.disabled { opacity: .35; pointer-events: none; }
  .btn.alt { background: transparent; color: var(--accent); border: 1px solid var(--accent); }
  .note { color: var(--muted); font-size: .9rem; margin: 12px 0 0; }
  ul { margin: 8px 0 0; padding-left: 1.2em; }
  footer { color: var(--muted); font-size: .85rem; text-align: center; margin-top: 28px; }
  a { color: var(--accent); }
</style>
</head>
<body>
<main>
  <h1>Akai Katana <span>Gold</span> Patcher</h1>
  <p class="lead">Patches the original Akai Katana program ROM (u4) with the Gold changes and builds a matching MiSTer <code>.mra</code>. Everything runs in your browser; your ROMs are never uploaded.</p>

  <section>
    <h2><b>1</b>Load your files</h2>
    <label id="drop" for="file">
      <p><strong>Drop <code>akatana.zip</code> here</strong>, or click to choose</p>
      <p><small>A loose <code>u4</code> works too. The <code>u4</code> must be the original, unpatched one (2010/ 8/13 MASTER VER., CRC32 <code>@INCRC@</code>).</small></p>
    </label>
    <input type="file" id="file" accept=".zip,application/zip,*/*">
  </section>

  <section>
    <h2><b>2</b>Check</h2>
    <div class="scroll"><table>
      <thead><tr><th>File</th><th>Expected CRC32</th><th>Found CRC32</th><th>Status</th></tr></thead>
      <tbody id="checks"><tr><td colspan="4" class="wait">Waiting for a file</td></tr></tbody>
    </table></div>
    <p id="msg"></p>
  </section>

  <section>
    <h2><b>3</b>Download</h2>
    <div class="scroll"><table>
      <thead><tr><th>File</th><th>Expected CRC32</th><th>Built CRC32</th><th>Status</th></tr></thead>
      <tbody><tr><td><code>u4</code> (Gold)</td><td><code>@OUTCRC@</code></td><td id="builtcrc">-</td><td id="builtst" class="wait">Waiting</td></tr></tbody>
    </table></div>
    <div class="btns" style="margin-top:14px">
      <a class="btn disabled" id="dlzip" href="#">Download akatanagold.zip</a>
      <a class="btn alt disabled" id="dlu4zip" href="#">u4.zip</a>
      <a class="btn alt disabled" id="dlu4" href="#">raw u4</a>
      <a class="btn alt" id="dlmra" href="#">Akai Katana Gold.mra (MiSTer)</a>
    </div>
    <p class="note"><code>akatanagold.zip</code> is the full set with <code>u4</code> replaced; <code>u2</code>, <code>u23</code> and <code>u24</code> are copied unchanged. On real hardware, keep a backup of your original u4 flash.</p>
    <p class="note"><b>MiSTer:</b> the <code>.mra</code> is for the ikacore CV1k core. Put it with your other arcade <code>.mra</code> files and <code>akatanagold.zip</code> in your MAME ROM folder (<code>games/mame</code>). It loads <code>akatanagold.zip</code> and checks for the Gold u4 (<code>@OUTCRC@</code>). After you load a zip, the <code>.mra</code> also uses the CRC32s of the <code>u2</code>, <code>u23</code> and <code>u24</code> it found, so it always matches your set.</p>
  </section>

  <section>
    <h2>Gold</h2>
    <p style="margin:0">Changes to gold in spirit form (念身):</p>
    <ul>
      <li><strong>Gold is collected automatically.</strong> Gold no longer circles the ship until spirit form ends. Each piece flies straight to the ship and is collected.</li>
      <li><strong>Each collected gold piece adds 1 HIT.</strong> HIT used to count gold as it appeared.</li>
      <li><strong>HIT never resets.</strong> It keeps counting for the whole game instead of clearing about 3 seconds after the last hit. The HIT number is still only shown while it's counting up.</li>
      <li>Because gold is collected straight away, it doesn't grow in value while it circles: every piece is worth 100 points. Gold from a defeated boss still starts at 10,000.</li>
    </ul>
    <p class="note">Source and details: <a href="https://github.com/GalaxyBrian/Akai_Katana_Gold">github.com/GalaxyBrian/Akai_Katana_Gold</a></p>
  </section>

  <footer>Not affiliated with or endorsed by Cave or exA-Arcadia. You must supply your own legally obtained ROM dump.</footer>
</main>

<script>
"use strict";
const ORIGINAL_CRC = @INCRCNUM@;
const OUT_CRC = @OUTCRCNUM@;
const U4_SIZE = 0x400000;
const PATCH = @PATCH@; // [file offset, base64 bytes] applied to the original u4
const MRA_TEMPLATE = @MRA@;
const DEFAULT_PART_CRC = { u2: "89a2e1a5", u23: "34a67e24", u24: "10760fed" };

const CRC_TABLE = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) {
    let c = n;
    for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    t[n] = c >>> 0;
  }
  return t;
})();
function crc32(u8) {
  let c = 0xffffffff;
  for (let i = 0; i < u8.length; i++) c = CRC_TABLE[(c ^ u8[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}
const hex = n => n.toString(16).padStart(8, "0");
const $ = id => document.getElementById(id);

function setChecks(rows) {
  $("checks").innerHTML = rows.map(r =>
    `<tr><td><code>${r.name}</code></td><td>${r.expected ? "<code>" + r.expected + "</code>" : "-"}</td>` +
    `<td>${r.found ? "<code>" + r.found + "</code>" : "-"}</td><td class="${r.cls}">${r.status}</td></tr>`).join("");
}
function msg(html, cls) { $("msg").className = cls || ""; $("msg").innerHTML = html; }
function resetOutputs() {
  for (const id of ["dlzip", "dlu4zip", "dlu4"]) {
    const a = $(id);
    a.classList.add("disabled");
    if (a.href.startsWith("blob:")) URL.revokeObjectURL(a.href);
    a.removeAttribute("href");
  }
  $("builtcrc").textContent = "-";
  $("builtst").textContent = "Waiting";
  $("builtst").className = "wait";
  mraLink(DEFAULT_PART_CRC, OUT_CRC);
}

// ---------- zip reading ----------
async function readZip(file) {
  const tailLen = Math.min(file.size, 65557);
  const tail = new Uint8Array(await file.slice(file.size - tailLen).arrayBuffer());
  let eocd = -1;
  for (let i = tail.length - 22; i >= 0; i--) {
    if (tail[i] === 0x50 && tail[i + 1] === 0x4b && tail[i + 2] === 5 && tail[i + 3] === 6) { eocd = i; break; }
  }
  if (eocd < 0) throw new Error("not a zip file");
  const dv = new DataView(tail.buffer, eocd);
  const count = dv.getUint16(10, true);
  const cdSize = dv.getUint32(12, true);
  const cdOff = dv.getUint32(16, true);
  if (cdOff === 0xffffffff || count === 0xffff) throw new Error("zip64 archives are not supported");
  const cd = new Uint8Array(await file.slice(cdOff, cdOff + cdSize).arrayBuffer());
  const cv = new DataView(cd.buffer);
  const entries = [];
  let p = 0;
  for (let n = 0; n < count; n++) {
    if (cv.getUint32(p, true) !== 0x02014b50) throw new Error("bad zip directory");
    const e = {
      method: cv.getUint16(p + 10, true),
      time: cv.getUint16(p + 12, true),
      date: cv.getUint16(p + 14, true),
      crc: cv.getUint32(p + 16, true),
      csize: cv.getUint32(p + 20, true),
      usize: cv.getUint32(p + 24, true),
      localOff: cv.getUint32(p + 42, true),
    };
    const nlen = cv.getUint16(p + 28, true), xlen = cv.getUint16(p + 30, true), clen = cv.getUint16(p + 32, true);
    e.fullName = new TextDecoder().decode(cd.subarray(p + 46, p + 46 + nlen));
    e.name = e.fullName.split("/").pop();
    p += 46 + nlen + xlen + clen;
    if (e.fullName.endsWith("/")) continue;
    const lh = new DataView(await file.slice(e.localOff, e.localOff + 30).arrayBuffer());
    if (lh.getUint32(0, true) !== 0x04034b50) throw new Error("bad zip entry header");
    e.dataOff = e.localOff + 30 + lh.getUint16(26, true) + lh.getUint16(28, true);
    e.raw = file.slice(e.dataOff, e.dataOff + e.csize);
    entries.push(e);
  }
  return entries;
}
async function entryData(e) {
  if (e.method === 0) return new Uint8Array(await e.raw.arrayBuffer());
  if (e.method !== 8) throw new Error(`${e.name}: unsupported compression method ${e.method}`);
  if (typeof DecompressionStream === "undefined") throw new Error("this browser can't unzip; try a current Chrome, Edge, Firefox or Safari, or drop a loose u4");
  const stream = e.raw.stream().pipeThrough(new DecompressionStream("deflate-raw"));
  return new Uint8Array(await new Response(stream).arrayBuffer());
}

// ---------- zip writing (other entries copied as-is, u4 stored) ----------
function u16(v) { return [v & 255, (v >>> 8) & 255]; }
function u32(v) { return [v & 255, (v >>> 8) & 255, (v >>> 16) & 255, (v >>> 24) & 255]; }
function dosNow() {
  const d = new Date();
  return {
    time: (d.getHours() << 11) | (d.getMinutes() << 5) | (d.getSeconds() >> 1),
    date: ((d.getFullYear() - 1980) << 9) | ((d.getMonth() + 1) << 5) | d.getDate(),
  };
}
function buildZip(items) {
  // items: {name, method, crc, csize, usize, time, date, data: Blob|Uint8Array}
  const parts = [], central = [];
  let off = 0;
  for (const it of items) {
    const name = new TextEncoder().encode(it.name);
    const head = new Uint8Array([
      ...u32(0x04034b50), ...u16(20), ...u16(0), ...u16(it.method), ...u16(it.time), ...u16(it.date),
      ...u32(it.crc), ...u32(it.csize), ...u32(it.usize), ...u16(name.length), ...u16(0), ...name]);
    central.push(new Uint8Array([
      ...u32(0x02014b50), ...u16(20), ...u16(20), ...u16(0), ...u16(it.method), ...u16(it.time), ...u16(it.date),
      ...u32(it.crc), ...u32(it.csize), ...u32(it.usize), ...u16(name.length), ...u16(0), ...u16(0),
      ...u16(0), ...u16(0), ...u32(0), ...u32(off), ...name]));
    parts.push(head, it.data);
    off += head.length + it.csize;
  }
  const cdSize = central.reduce((s, c) => s + c.length, 0);
  const end = new Uint8Array([
    ...u32(0x06054b50), ...u16(0), ...u16(0), ...u16(items.length), ...u16(items.length),
    ...u32(cdSize), ...u32(off), ...u16(0)]);
  return new Blob([...parts, ...central, end], { type: "application/zip" });
}

// ---------- patch ----------
function applyPatch(u4) {
  const out = new Uint8Array(u4);
  for (const [off, b64] of PATCH) {
    const bytes = Uint8Array.from(atob(b64), c => c.charCodeAt(0));
    out.set(bytes, off);
  }
  return out;
}
function buildMra(parts, u4crc) {
  return MRA_TEMPLATE
    .replace(/(<part name="u2"\s+crc=")[0-9a-f]{8}(")/, "$1" + parts.u2 + "$2")
    .replace(/(<part name="u23"\s+crc=")[0-9a-f]{8}(")/, "$1" + parts.u23 + "$2")
    .replace(/(<part name="u24"\s+crc=")[0-9a-f]{8}(")/, "$1" + parts.u24 + "$2")
    .replace("@U4CRC@", hex(u4crc));
}
function mraLink(parts, u4crc) {
  const a = $("dlmra");
  if (a.href && a.href.startsWith("blob:")) URL.revokeObjectURL(a.href);
  a.href = URL.createObjectURL(new Blob([buildMra(parts, u4crc)], { type: "application/xml" }));
  a.download = "Akai Katana Gold.mra";
}
document.addEventListener("DOMContentLoaded", () => mraLink(DEFAULT_PART_CRC, OUT_CRC));
function link(id, blob, filename) {
  const a = $(id);
  a.href = URL.createObjectURL(blob);
  a.download = filename;
  a.classList.remove("disabled");
}

async function handle(file) {
  resetOutputs();
  msg("Reading " + file.name + "…", "wait");
  try {
    let entries = null, u4;
    const head = new Uint8Array(await file.slice(0, 4).arrayBuffer());
    const isZip = head[0] === 0x50 && head[1] === 0x4b;
    const rows = [];
    const parts = Object.assign({}, DEFAULT_PART_CRC);
    if (isZip) {
      entries = await readZip(file);
      const e = entries.find(x => x.name.toLowerCase() === "u4");
      if (!e) {
        setChecks(entries.map(x => ({ name: x.fullName, found: hex(x.crc), status: "-", cls: "wait" })));
        msg("No <code>u4</code> in this zip.", "bad");
        return;
      }
      u4 = await entryData(e);
      for (const x of entries) {
        if (x === e) continue;
        const key = x.name.toLowerCase();
        let status = "Copied unchanged", cls = "wait", expected = "";
        if (key in DEFAULT_PART_CRC) {
          expected = DEFAULT_PART_CRC[key];
          parts[key] = hex(x.crc);
          if (hex(x.crc) === expected) { status = "OK, copied unchanged"; cls = "ok"; }
          else { status = "Different dump, copied unchanged"; cls = "warn"; }
        }
        rows.push({ name: x.fullName, expected, found: hex(x.crc), status, cls });
      }
      for (const key of Object.keys(DEFAULT_PART_CRC)) {
        if (!entries.some(x => x.name.toLowerCase() === key)) rows.push({ name: key, expected: DEFAULT_PART_CRC[key], status: "Missing", cls: "bad" });
      }
    } else {
      u4 = new Uint8Array(await file.arrayBuffer());
    }
    const crc = crc32(u4);
    let status, cls, note;
    if (u4.length !== U4_SIZE) {
      status = "Wrong size"; cls = "bad"; note = "<code>u4</code> must be exactly 4 MB.";
    } else if (crc === ORIGINAL_CRC) {
      status = "Original u4"; cls = "ok";
    } else if (crc === OUT_CRC) {
      status = "Already Gold"; cls = "ok"; note = "This u4 already has the Gold patch. Nothing to do.";
    } else {
      status = "Unknown u4"; cls = "bad"; note = "This u4 doesn't match the supported version (2010/ 8/13 MASTER VER.).";
    }
    rows.unshift({ name: "u4", expected: hex(ORIGINAL_CRC), found: hex(crc), status, cls });
    setChecks(rows);
    if (crc !== ORIGINAL_CRC) { msg(note || "", cls); return; }

    msg("Patching…", "wait");
    const out = applyPatch(u4);
    const outCrc = crc32(out);
    $("builtcrc").innerHTML = "<code>" + hex(outCrc) + "</code>";
    if (outCrc !== OUT_CRC) {
      $("builtst").textContent = "Mismatch"; $("builtst").className = "bad";
      msg("The patched u4 doesn't have the expected CRC32. Nothing was produced.", "bad");
      return;
    }
    $("builtst").textContent = "OK"; $("builtst").className = "ok";
    mraLink(parts, outCrc);

    const t = dosNow();
    const u4Item = { name: "u4", method: 0, crc: outCrc, csize: out.length, usize: out.length, time: t.time, date: t.date, data: out };
    link("dlu4", new Blob([out], { type: "application/octet-stream" }), "u4");
    link("dlu4zip", buildZip([u4Item]), "u4.zip");
    if (entries) {
      const items = entries.map(x => x.name.toLowerCase() === "u4" ? u4Item :
        { name: x.name, method: x.method, crc: x.crc, csize: x.csize, usize: x.usize, time: x.time, date: x.date, data: x.raw });
      link("dlzip", buildZip(items), "akatanagold.zip");
      msg("Done. Your patched files and a matching <code>.mra</code> are ready below.", "ok");
    } else {
      msg("Done. Drop the full <code>akatana.zip</code> instead if you also want the complete set.", "ok");
    }
  } catch (err) {
    msg("Error: " + err.message, "bad");
  }
}

const input = $("file");
input.addEventListener("change", () => { if (input.files[0]) handle(input.files[0]); input.value = ""; });
// Accept a drop anywhere on the page, and never let the browser open the file instead.
let dragDepth = 0;
function hasFiles(e) { return e.dataTransfer && Array.from(e.dataTransfer.types || []).includes("Files"); }
window.addEventListener("dragenter", e => {
  if (!hasFiles(e)) return;
  e.preventDefault();
  dragDepth++;
  document.body.classList.add("dragging");
});
window.addEventListener("dragover", e => {
  if (!hasFiles(e)) return;
  e.preventDefault();
  e.dataTransfer.dropEffect = "copy";
});
window.addEventListener("dragleave", e => {
  if (!hasFiles(e)) return;
  dragDepth = Math.max(0, dragDepth - 1);
  if (dragDepth === 0) document.body.classList.remove("dragging");
});
window.addEventListener("drop", e => {
  e.preventDefault();
  dragDepth = 0;
  document.body.classList.remove("dragging");
  const f = e.dataTransfer && e.dataTransfer.files && e.dataTransfer.files[0];
  if (f) handle(f);
});
</script>
</body>
</html>
'''
IN=0x613fd380; OUT=0xd899ec64
html=(html.replace('@INCRCNUM@',hex(IN)).replace('@OUTCRCNUM@',hex(OUT))
      .replace('@INCRC@','%08x'%IN).replace('@OUTCRC@','%08x'%OUT)
      .replace('@PATCH@',json.dumps(patch)).replace('@MRA@',json.dumps(mra)))
open(os.path.join(HERE, '..', '..', 'index.html'),'w').write(html)
# static MRA with the default CRCs
open(os.path.join(HERE, '..', '..', 'mister', 'Akai Katana Gold.mra'),'w').write(mra.replace('@U4CRC@','%08x'%OUT))
print(len(html))
