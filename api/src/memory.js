/**
 * Memory — per-user Associate Agent memory store.
 *
 *   GET  /api/memory/:userId   → list entries
 *   POST /api/memory/:userId   → append: { entry: { role, text } }
 *
 * Persistence tiers:
 *   1. In-process Map (fastest — for a session's duration)
 *   2. JSON file in .data/memory/ (survives restarts — default for MVP)
 *   3. Postgres + Qdrant (coming: see db/migrations/002_memory.sql)
 *
 * The JSON files are written on every append. For large households with
 * high conversation volume, swap tier 2 for tier 3 via env flag.
 */

const fs = require('fs');
const path = require('path');

const DATA_DIR = path.resolve(process.env.MEMORY_DIR || path.join(__dirname, '../../.data/memory'));

function ensureDataDir() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
}

function filePath(userId) {
  return path.join(DATA_DIR, `${userId.replace(/[^a-z0-9_-]/gi, '_')}.json`);
}

function loadFromDisk(userId) {
  ensureDataDir();
  const fp = filePath(userId);
  if (!fs.existsSync(fp)) return [];
  try { return JSON.parse(fs.readFileSync(fp, 'utf8')); } catch { return []; }
}

function saveToDisk(userId, entries) {
  ensureDataDir();
  fs.writeFileSync(filePath(userId), JSON.stringify(entries, null, 2));
}

// In-process cache: populated lazily on first access
const cache = new Map();

function getEntries(userId) {
  if (!cache.has(userId)) cache.set(userId, loadFromDisk(userId));
  return cache.get(userId);
}

function write(userId, entry) {
  const stamped = { role: entry.role, text: entry.text, ts: Date.now() };
  const entries = getEntries(userId);
  entries.push(stamped);
  saveToDisk(userId, entries);
  return { entry: stamped, total: entries.length };
}

function read(userId) {
  return getEntries(userId);
}

function get(req, res) {
  const { userId } = req.params;
  res.json({ userId, entries: read(userId) });
}

function append(req, res) {
  const { userId } = req.params;
  const { entry } = req.body || {};
  if (!entry || typeof entry !== 'object')
    return res.status(400).json({ error: 'missing_entry' });
  if (!entry.role || !entry.text)
    return res.status(400).json({ error: 'entry_requires_role_and_text' });
  const result = write(userId, entry);
  res.json({ ok: true, ...result });
}

module.exports = { get, append, write, read };
