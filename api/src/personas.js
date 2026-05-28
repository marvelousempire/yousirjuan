/**
 * Associate Agent registry — "Your World, Your Lens"
 *
 * Each entry encodes one member's personalized paradigm (how the interface
 * is rendered for them) and their Associate Agent (the AI companion that
 * speaks, remembers, and acts on their behalf).
 *
 * Terminology: these AI companions are ASSOCIATE AGENTS — never "butlers"
 * or "personas". The data type is called Persona because it's the shape
 * of the record, but user-facing text always says "associate" or "your agent".
 *
 * Production: backed by Postgres (see db/migrations/001_personas.sql).
 * The in-memory seed here is the canonical source of truth for MVP until
 * the DB migration runs. `patch()` writes to both.
 */

const store = {
  u_avery: {
    userId: 'u_avery',
    name: 'Avery Goodman',
    household: 'yousirjuan',
    role: 'principal',
    paradigm: {
      palette: 'obsidian',
      accent: '#7C5CFF',
      background: '#0A0A12',
      foreground: '#F5F3FF',
      layout: 'executive-grid',
      labelSet: 'executive',
      typography: 'serif-strong',
      mood: 'focused',
    },
    agent: {
      name: 'Sterling',
      voice: 'deep_male_calm',
      persona: 'executive-associate',
      avatar: null,
      greeting: 'Welcome back, Avery. The household is steady.',
    },
  },

  u_bobby: {
    userId: 'u_bobby',
    name: 'Robert Bobby',
    household: 'yousirjuan',
    role: 'partner',
    paradigm: {
      palette: 'copper',
      accent: '#FF6B35',
      background: '#180E08',
      foreground: '#FFF0E6',
      layout: 'soft-stack',
      labelSet: 'warm',
      typography: 'humanist-rounded',
      mood: 'warm',
    },
    agent: {
      name: 'Blake',
      voice: 'warm_male_friendly',
      persona: 'warm-associate',
      avatar: null,
      greeting: 'Hey Bobby — what are we taking on today?',
    },
  },

  u_nivram: {
    userId: 'u_nivram',
    name: 'NIVRAM',
    household: 'yousirjuan',
    role: 'architect',
    paradigm: {
      palette: 'matrix',
      accent: '#00FF88',
      background: '#000A05',
      foreground: '#C0FFD8',
      layout: 'developer-dense',
      labelSet: 'technical',
      typography: 'monospace-sharp',
      mood: 'systematic',
    },
    agent: {
      name: 'Cipher',
      voice: 'precise_neutral_tech',
      persona: 'technical-associate',
      avatar: null,
      greeting: 'Session initialized. Ready for input, NIVRAM.',
    },
  },

  u_yousirjuan: {
    userId: 'u_yousirjuan',
    name: 'Yousir Juan',
    household: 'yousirjuan',
    role: 'founder',
    paradigm: {
      palette: 'full',
      accent: '#FFD700',
      background: '#0A0800',
      foreground: '#FFFAE0',
      layout: 'command-center',
      labelSet: 'full',
      typography: 'display-bold',
      mood: 'commanding',
    },
    agent: {
      name: 'Full',
      voice: 'resonant_authority',
      persona: 'full-associate',
      avatar: null,
      greeting: 'The domain is yours, Yousir. What is your directive?',
    },
  },
};

function getPersona(userId) {
  return store[userId] || null;
}

function listPersonas() {
  return Object.values(store);
}

function patch(userId, updates) {
  if (!store[userId]) return null;
  if (updates.paradigm) {
    Object.assign(store[userId].paradigm, updates.paradigm);
  }
  if (updates.agent) {
    Object.assign(store[userId].agent, updates.agent);
  }
  return store[userId];
}

module.exports = { getPersona, listPersonas, patch };
