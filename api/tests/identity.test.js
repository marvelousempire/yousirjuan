const identity = require('../src/identity');

describe('identity', () => {
  test('resolveFace maps all 4 seeded face IDs', () => {
    expect(identity.resolveFace('face-avery-001')).toBe('u_avery');
    expect(identity.resolveFace('face-bobby-001')).toBe('u_bobby');
    expect(identity.resolveFace('face-nivram-001')).toBe('u_nivram');
    expect(identity.resolveFace('face-yousirjuan-001')).toBe('u_yousirjuan');
  });

  test('resolveFace returns null for unknown face', () => {
    expect(identity.resolveFace('face-unknown-999')).toBeNull();
  });

  test('registerFace adds a new mapping', () => {
    identity.registerFace('face-test-001', 'u_avery');
    expect(identity.resolveFace('face-test-001')).toBe('u_avery');
  });

  test('listEnrolledFaces returns at least 4 entries', () => {
    const faces = identity.listEnrolledFaces();
    expect(faces.length).toBeGreaterThanOrEqual(4);
    expect(faces[0]).toHaveProperty('faceId');
    expect(faces[0]).toHaveProperty('userId');
  });
});
