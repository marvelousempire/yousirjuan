require('dotenv').config();

const crypto = require('crypto');
const http = require('http');
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const app = express();
const server = http.createServer(app);

// CORS — tightened to known origins. Add your household domain here.
const ALLOWED_ORIGINS = (process.env.CORS_ORIGINS || 'http://localhost:3000,http://localhost:4000')
  .split(',').map((o) => o.trim());

app.use(cors({
  origin: (origin, cb) => {
    // Allow server-side/non-browser calls (curl, iOS native) and allowed origins.
    if (!origin || ALLOWED_ORIGINS.includes(origin)) return cb(null, true);
    cb(new Error(`CORS: ${origin} not allowed`));
  },
  credentials: true,
}));

app.use(helmet({
  contentSecurityPolicy: false, // Next.js handles its own CSP
}));
app.use(express.json({ limit: '25mb' }));
app.use(morgan('dev'));

// Modules
const namespaces = require('./src/namespaces');
const features   = require('./src/features');
const health     = require('./src/health');
const session    = require('./src/session');
const personas   = require('./src/personas');
const memory     = require('./src/memory');
const voice      = require('./src/voice');
const identity   = require('./src/identity');
const auth       = require('./src/auth');
const wsVoice    = require('./src/ws-voice');

// SSE client registry: userId → Set<ServerResponse>
const sseClients = new Map();

function broadcastParadigmUpdate(userId, paradigm) {
  const clients = sseClients.get(userId);
  if (!clients) return;
  const payload = JSON.stringify({ type: 'paradigm_updated', paradigm });
  for (const res of clients) {
    try { res.write(`data: ${payload}\n\n`); } catch (_) {}
  }
}

// ─── Public routes (no token required) ────────────────────────────────────────

app.get('/health', health.status);
app.get('/api/features', features.list);
app.get('/api/namespaces/:id', namespaces.getNamespace);
app.post('/api/namespaces/resolve', namespaces.resolve);

// Session start — biometric proof from client; returns a signed token.
app.post('/api/session', async (req, res) => {
  const { faceId } = req.body || {};
  if (!faceId) return res.status(400).json({ error: 'missing_face_id' });
  const userId = identity.resolveFace(faceId);
  if (!userId) return res.status(404).json({ error: 'unknown_face', faceId });
  const persona = personas.getPersona(userId);
  if (!persona) return res.status(404).json({ error: 'no_persona', userId });
  const sessionId = `s_${Date.now()}_${crypto.randomBytes(4).toString('hex')}`;
  const token = auth.issueToken(userId, sessionId);
  res.json({ sessionId, userId, persona, token, issuedAt: new Date().toISOString() });
});

// Identity: list enrolled faces
app.get('/api/identity/faces', (_req, res) =>
  res.json({ enrolled: identity.listEnrolledFaces() }));

// Identity: enroll a new face (from kiosk camera flow)
app.post('/api/identity/enroll', (req, res) => {
  const { faceId, userId, displayName } = req.body || {};
  if (!faceId || !userId) return res.status(400).json({ error: 'missing_fields' });
  identity.registerFace(faceId, userId);
  res.json({ ok: true, faceId, userId, displayName });
});

// WebAuthn challenge stub — real FIDO2 verification is post-MVP
app.get('/api/auth/webauthn/challenge', (_req, res) => {
  res.json({ challenge: crypto.randomBytes(32).toString('base64url') });
});

// ─── Authenticated routes (token required) ────────────────────────────────────

app.get('/api/personas', auth.requireAuth, (_req, res) =>
  res.json({ personas: personas.listPersonas() }));

app.get('/api/personas/:userId', auth.requireAuth, (req, res) => {
  const p = personas.getPersona(req.params.userId);
  if (!p) return res.status(404).json({ error: 'not_found' });
  res.json(p);
});

// Gap 10: Paradigm editor — PATCH paradigm fields; broadcasts SSE on save
app.patch('/api/personas/:userId', auth.requireAuth, (req, res) => {
  const { userId } = req.params;
  const { paradigm } = req.body || {};
  if (!paradigm || typeof paradigm !== 'object')
    return res.status(400).json({ error: 'missing_paradigm' });
  const updated = personas.patch(userId, { paradigm });
  if (!updated) return res.status(404).json({ error: 'not_found' });
  broadcastParadigmUpdate(userId, updated.paradigm);
  res.json(updated);
});

app.get('/api/memory/:userId', auth.requireAuth, memory.get);
app.post('/api/memory/:userId', auth.requireAuth, memory.append);
app.post('/api/voice/turn', auth.requireAuth, voice.turn);

// Elevation C: "Train your Associate" — onboarding write
app.post('/api/onboard/:userId', auth.requireAuth, (req, res) => {
  const { userId } = req.params;
  const { preferredName, voicePreference, lessons } = req.body || {};
  if (preferredName) memory.write(userId, { role: 'config', text: `preferred_name: ${preferredName}` });
  if (voicePreference) memory.write(userId, { role: 'config', text: `voice: ${voicePreference}` });
  if (Array.isArray(lessons)) {
    lessons.forEach((l) => {
      if (l?.trim()) memory.write(userId, { role: 'training', text: l });
    });
  }
  // Patch the agent voice if requested
  if (voicePreference) personas.patch(userId, { agent: { voice: voicePreference } });
  res.json({ ok: true, memory: memory.read(userId).length });
});

// Elevation D: SSE paradigm sync
app.get('/api/sync/:userId', auth.requireAuth, (req, res) => {
  const { userId } = req.params;
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.setHeader('X-Accel-Buffering', 'no');
  res.flushHeaders();
  if (!sseClients.has(userId)) sseClients.set(userId, new Set());
  sseClients.get(userId).add(res);
  const timer = setInterval(() => { try { res.write(': keep-alive\n\n'); } catch (_) {} }, 30_000);
  req.on('close', () => {
    clearInterval(timer);
    sseClients.get(userId)?.delete(res);
  });
});

// ─── WebSocket voice channel (Elevation B — barge-in) ─────────────────────────
wsVoice.attach(server);

// ─── Boot ─────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 4000;

server.listen(PORT, () => {
  console.log(`Sovereign API runtime listening on ${PORT}`);
  console.log(`  REST: http://localhost:${PORT}`);
  console.log(`  Voice WS: ws://localhost:${PORT}/api/voice/ws`);
});
