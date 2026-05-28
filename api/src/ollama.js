/**
 * Ollama client — local LLM inference via the Ollama REST API.
 *
 * The companion model is llama3.3:70b by default; falls back to llama3.2:3b
 * for devices without enough VRAM, or to stub mode if Ollama isn't running.
 *
 * Each Associate Agent has a system prompt that encodes their persona so the
 * model speaks in their voice, not as a generic assistant.
 */

const OLLAMA_URL = process.env.OLLAMA_URL || 'http://localhost:11434';
const PRIMARY_MODEL = process.env.OLLAMA_MODEL || 'llama3.3:70b';
const FALLBACK_MODEL = 'llama3.2:3b';

const SYSTEM_PROMPTS = {
  'executive-associate': `You are Sterling, the executive Associate Agent for Avery Goodman.
Speak with precision and calm authority. You are formal, concise, and solution-oriented.
You manage the household intelligence for a family office. You address Avery by first name.
Keep responses short — 1-3 sentences unless asked for detail.`,

  'warm-associate': `You are Blake, the Associate Agent for Robert Bobby.
You are warm, direct, and encouraging. You speak like a trusted advisor who's also a friend.
Keep it conversational — not overly formal. Address Bobby by his first name.
Keep responses short and human.`,

  'technical-associate': `You are Cipher, the Associate Agent for NIVRAM.
You speak with technical precision. Favor structured responses when relevant.
You may use technical shorthand. Address NIVRAM directly. No fluff.
Be systematically helpful. Short, signal-dense responses.`,

  'full-associate': `You are Full, the Associate Agent for Yousir Juan.
You speak with gravitas and authority, as a trusted counselor to a founder.
You are direct, strategic, and commanding in your tone. Address them as "Yousir".
Responses are declarative, never hedging.`,
};

async function chat(personaType, messages, timeout = 30000) {
  const systemPrompt = SYSTEM_PROMPTS[personaType] || SYSTEM_PROMPTS['executive-associate'];

  const payload = {
    model: PRIMARY_MODEL,
    messages: [
      { role: 'system', content: systemPrompt },
      ...messages.map((m) => ({ role: m.role === 'agent' ? 'assistant' : 'user', content: m.text })),
    ],
    stream: false,
    options: { temperature: 0.7, num_predict: 200 },
  };

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeout);

  try {
    const res = await fetch(`${OLLAMA_URL}/api/chat`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });
    clearTimeout(timer);

    if (!res.ok) {
      // Try smaller model if primary isn't pulled.
      if (res.status === 404 && payload.model !== FALLBACK_MODEL) {
        payload.model = FALLBACK_MODEL;
        const r2 = await fetch(`${OLLAMA_URL}/api/chat`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(payload),
        });
        if (!r2.ok) throw new Error(`ollama_http_${r2.status}`);
        const d2 = await r2.json();
        return d2.message?.content || '';
      }
      throw new Error(`ollama_http_${res.status}`);
    }

    const data = await res.json();
    return data.message?.content || '';
  } catch (err) {
    clearTimeout(timer);
    if (err.name === 'AbortError') throw new Error('ollama_timeout');
    throw err;
  }
}

async function isAvailable() {
  try {
    const r = await fetch(`${OLLAMA_URL}/api/tags`, { signal: AbortSignal.timeout(2000) });
    return r.ok;
  } catch {
    return false;
  }
}

module.exports = { chat, isAvailable };
