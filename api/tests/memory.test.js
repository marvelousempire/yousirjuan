process.env.MEMORY_DIR = '/tmp/ysj-test-memory-' + Date.now();

const memory = require('../src/memory');

const TEST_USER = 'u_test_memory';

afterAll(() => {
  // Clean up test memory files
  const fs = require('fs');
  const path = require('path');
  const dir = process.env.MEMORY_DIR;
  if (fs.existsSync(dir)) fs.rmSync(dir, { recursive: true });
});

describe('memory', () => {
  test('write + read roundtrip', () => {
    memory.write(TEST_USER, { role: 'user', text: 'Hello from test' });
    const entries = memory.read(TEST_USER);
    expect(entries.length).toBeGreaterThanOrEqual(1);
    const last = entries[entries.length - 1];
    expect(last.role).toBe('user');
    expect(last.text).toBe('Hello from test');
    expect(last.ts).toBeDefined();
  });

  test('write persists to disk', () => {
    const path = require('path');
    const fs = require('fs');
    memory.write(TEST_USER, { role: 'agent', text: 'Persisted.' });
    const fp = path.join(process.env.MEMORY_DIR, `${TEST_USER}.json`);
    expect(fs.existsSync(fp)).toBe(true);
    const disk = JSON.parse(fs.readFileSync(fp, 'utf8'));
    expect(disk.some((e) => e.text === 'Persisted.')).toBe(true);
  });

  test('supports config and training roles', () => {
    memory.write(TEST_USER, { role: 'config', text: 'preferred_name: Test' });
    memory.write(TEST_USER, { role: 'training', text: 'We eat dinner at 7pm.' });
    const entries = memory.read(TEST_USER);
    expect(entries.some((e) => e.role === 'config')).toBe(true);
    expect(entries.some((e) => e.role === 'training')).toBe(true);
  });
});
