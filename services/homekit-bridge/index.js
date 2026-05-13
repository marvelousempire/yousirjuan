/**
 * HomeKit Bridge — Elevation J
 *
 * Translates natural-language directives from the Associate Agent into
 * HomeKit automation commands. Runs as a sidecar service.
 *
 * Architecture:
 *   Associate Agent (voice turn) → POST /homekit/action → this bridge
 *   → HomeKit via node-hap (HAP-nodejs) simulation
 *
 * Phase 1 (this file): intent parsing + stubbed device control.
 * Phase 2: wire to real HAP-nodejs accessories on the home network.
 *
 * Supported intents:
 *   - "set the lights [to/for] <scene>" → lights action
 *   - "lock the [front] door" → lock action
 *   - "set the thermostat to <N> degrees" → climate action
 *   - "turn [on|off] <device>" → toggle action
 */

require('dotenv').config({ path: '../../.env' });

const express = require('express');
const app = express();
app.use(express.json());

// ─── Intent Recognition ───────────────────────────────────────────────────────

const INTENT_PATTERNS = [
  { re: /set.+lights?\s+(?:to\s+)?(.+)/i,       type: 'lights',    extract: (m) => ({ scene: m[1].trim() }) },
  { re: /turn\s+(on|off)\s+(.+)/i,               type: 'toggle',    extract: (m) => ({ state: m[1], device: m[2].trim() }) },
  { re: /lock\s+(?:the\s+)?(.+)\s+door/i,        type: 'lock',      extract: (m) => ({ target: m[1].trim() }) },
  { re: /set.+thermostat.+?(\d+)/i,              type: 'climate',   extract: (m) => ({ degrees: parseInt(m[1], 10) }) },
  { re: /(?:start|play|stop)\s+(.+)/i,           type: 'media',     extract: (m) => ({ command: m[1].trim() }) },
];

function parseIntent(text) {
  const t = (text || '').trim();
  for (const { re, type, extract } of INTENT_PATTERNS) {
    const m = t.match(re);
    if (m) return { type, params: extract(m), raw: t };
  }
  return { type: 'unknown', params: {}, raw: t };
}

// ─── Device stubs (replace with HAP-nodejs in Phase 2) ───────────────────────

const deviceRegistry = {
  lights: { living_room: 'off', kitchen: 'off', master: 'off', entry: 'off' },
  locks:  { front: 'locked', back: 'locked', garage: 'locked' },
  climate: { setpoint: 72 },
};

function executeIntent(intent, userId) {
  const { type, params } = intent;
  switch (type) {
    case 'lights':
      return { ok: true, type, action: `Lights set to "${params.scene}" scene.`, stub: true };
    case 'toggle':
      return { ok: true, type, action: `${params.device} turned ${params.state}.`, stub: true };
    case 'lock':
      deviceRegistry.locks[params.target.toLowerCase()] = 'locked';
      return { ok: true, type, action: `${params.target} door locked.`, stub: true };
    case 'climate':
      deviceRegistry.climate.setpoint = params.degrees;
      return { ok: true, type, action: `Thermostat set to ${params.degrees}°.`, stub: true };
    case 'media':
      return { ok: true, type, action: `Media command "${params.command}" sent.`, stub: true };
    default:
      return { ok: false, type: 'unknown', action: 'Intent not recognized.', stub: true };
  }
}

// ─── Routes ───────────────────────────────────────────────────────────────────

app.get('/health', (_req, res) => res.json({ ok: true, service: 'homekit-bridge' }));

// POST /homekit/action — called by the voice turn handler when Ollama output
// contains a home-control directive (detected by simple keyword scan in voice.js)
app.post('/homekit/action', (req, res) => {
  const { text, userId } = req.body || {};
  if (!text) return res.status(400).json({ error: 'missing_text' });
  const intent = parseIntent(text);
  const result = executeIntent(intent, userId);
  console.log(`[homekit] ${userId}: ${intent.type} — ${result.action}`);
  res.json({ ...result, intent });
});

// GET /homekit/state — snapshot of all device states
app.get('/homekit/state', (_req, res) => res.json(deviceRegistry));

const PORT = process.env.HOMEKIT_BRIDGE_PORT || 4002;
app.listen(PORT, () => console.log(`HomeKit bridge listening on ${PORT}`));

module.exports = { parseIntent }; // exported for tests
