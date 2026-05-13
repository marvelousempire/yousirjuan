/**
 * Voice — POST /api/voice/turn
 *
 * Request body: { userId, utterance }
 * Response:     { reply, agent, audio: null }
 *
 * Uses Ollama (local LLM) with the Associate Agent's persona injected as
 * a system prompt. Falls back to a stub response if Ollama isn't running —
 * so the demo works offline too.
 *
 * Phase 2: switch REST to WebSocket (`WS /api/voice`) and stream TTS audio
 * back from Kokoro so the agent speaks as it generates.
 */

const personas = require('./personas');
const memory = require('./memory');
const ollama = require('./ollama');

function stubReply(persona, utterance) {
  const agent = persona.agent;
  const u = (utterance || '').trim().toLowerCase();
  if (!u) return agent.greeting;
  if (u.includes('hello') || u.includes('hi') || u.includes('hey'))
    return agent.greeting;
  if (u.includes('your name') || u.includes('who are you'))
    return `I'm ${agent.name}, your Associate Agent. What can I do for you, ${persona.name.split(' ')[0]}?`;
  if (u.includes('calendar') || u.includes('today') || u.includes('schedule'))
    return `Pulling up your day, ${persona.name.split(' ')[0]}. The household runtime is nominal.`;
  if (u.includes('thank'))
    return `Of course, ${persona.name.split(' ')[0]}.`;
  return `I heard you. I'm ready to help — ask me anything, ${persona.name.split(' ')[0]}.`;
}

async function turn(req, res) {
  const { userId, utterance } = req.body || {};
  if (!userId) return res.status(400).json({ error: 'missing_user_id' });

  const persona = personas.getPersona(userId);
  if (!persona) return res.status(404).json({ error: 'unknown_user', userId });

  // Fetch recent conversation history for context (last 10 turns).
  const history = memory.read(userId).slice(-10);

  let reply;
  try {
    if (await ollama.isAvailable()) {
      const messages = [...history, { role: 'user', text: utterance || '' }];
      reply = await ollama.chat(persona.agent.persona, messages);
    } else {
      reply = stubReply(persona, utterance);
    }
  } catch (err) {
    // Ollama timed out or errored — fall back gracefully.
    reply = stubReply(persona, utterance);
  }

  if (utterance) memory.write(userId, { role: 'user', text: utterance });
  memory.write(userId, { role: 'agent', text: reply });

  res.json({ reply, agent: persona.agent, audio: null });
}

module.exports = { turn };
