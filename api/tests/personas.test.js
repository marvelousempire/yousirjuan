const personas = require('../src/personas');

describe('personas', () => {
  test('getPersona returns all 4 Associates', () => {
    const ids = ['u_avery', 'u_bobby', 'u_nivram', 'u_yousirjuan'];
    for (const id of ids) {
      const p = personas.getPersona(id);
      expect(p).not.toBeNull();
      expect(p.userId).toBe(id);
      expect(p.agent).toBeDefined();
      expect(p.paradigm).toBeDefined();
    }
  });

  test('getPersona returns null for unknown userId', () => {
    expect(personas.getPersona('u_nobody')).toBeNull();
  });

  test('listPersonas returns all 4', () => {
    expect(personas.listPersonas()).toHaveLength(4);
  });

  test('each persona has the required Associate Agent fields', () => {
    for (const p of personas.listPersonas()) {
      expect(p.agent.name).toBeTruthy();
      expect(p.agent.voice).toBeTruthy();
      expect(p.agent.greeting).toBeTruthy();
      expect(p.paradigm.accent).toMatch(/^#[0-9A-Fa-f]{6}$/);
      expect(p.paradigm.background).toMatch(/^#[0-9A-Fa-f]{6}$/);
    }
  });

  test('patch updates paradigm accent', () => {
    const before = personas.getPersona('u_avery').paradigm.accent;
    const updated = personas.patch('u_avery', { paradigm: { accent: '#AABBCC' } });
    expect(updated.paradigm.accent).toBe('#AABBCC');
    // Restore
    personas.patch('u_avery', { paradigm: { accent: before } });
  });

  test('patch returns null for unknown userId', () => {
    expect(personas.patch('u_nobody', { paradigm: {} })).toBeNull();
  });
});
