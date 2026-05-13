/**
 * WebSocket voice channel — bidirectional, barge-in capable.
 *
 * Protocol:
 *   client → server: { type: 'utterance', userId, text }
 *   server → client: { type: 'token', text }        — streaming token (Phase 2: real streaming)
 *   server → client: { type: 'done', reply, agent }  — full reply ready, play TTS
 *   server → client: { type: 'error', message }
 *
 * Barge-in: if the client sends a new 'utterance' while the server is
 * generating, the in-flight generation is cancelled and the new turn begins.
 * This is handled via the `abortControllers` map below.
 */

const { WebSocketServer } = require('ws');
const personas = require('./personas');
const memory = require('./memory');
const ollama = require('./ollama');

const abortControllers = new Map(); // userId → AbortController

function attach(server) {
  const wss = new WebSocketServer({ server, path: '/api/voice/ws' });

  wss.on('connection', (ws) => {
    ws.on('message', async (raw) => {
      let msg;
      try { msg = JSON.parse(raw); } catch { return; }

      if (msg.type !== 'utterance') return;
      const { userId, text: utterance } = msg;
      if (!userId || !utterance?.trim()) return;

      const persona = personas.getPersona(userId);
      if (!persona) {
        ws.send(JSON.stringify({ type: 'error', message: 'unknown_user' }));
        return;
      }

      // Barge-in: cancel any in-flight generation for this user.
      if (abortControllers.has(userId)) {
        abortControllers.get(userId).abort();
      }
      const ac = new AbortController();
      abortControllers.set(userId, ac);

      // Write the user's utterance to memory.
      if (utterance) memory.write(userId, { role: 'user', text: utterance });

      // Attempt real LLM; fall back to stub.
      let reply;
      try {
        const history = memory.read(userId).slice(-10);
        const messages = [...history, { role: 'user', text: utterance }];

        if (await ollama.isAvailable()) {
          // Phase 2: use streaming=true and emit tokens as they arrive.
          // For now, full response then done.
          reply = await ollama.chat(persona.agent.persona, messages);
        } else {
          reply = fallbackReply(persona, utterance);
        }
      } catch (err) {
        if (err.name === 'AbortError' || ac.signal.aborted) return; // barged in
        reply = fallbackReply(persona, utterance);
      }

      if (ac.signal.aborted) return; // barged in after LLM completed
      abortControllers.delete(userId);

      memory.write(userId, { role: 'agent', text: reply });

      if (ws.readyState === ws.OPEN) {
        ws.send(JSON.stringify({ type: 'done', reply, agent: persona.agent }));
      }
    });

    ws.on('close', () => {});
  });

  return wss;
}

function fallbackReply(persona, utterance) {
  const u = (utterance || '').toLowerCase();
  const name = persona.name.split(' ')[0];
  if (!u || u.match(/^(hello|hi|hey)/)) return persona.agent.greeting;
  if (u.includes('thank')) return `Of course, ${name}.`;
  return `Ready, ${name}. I'll respond fully once the local model is running.`;
}

module.exports = { attach };
