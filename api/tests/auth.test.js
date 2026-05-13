const auth = require('../src/auth');

describe('auth tokens', () => {
  test('issueToken + verify roundtrip', () => {
    const token = auth.issueToken('u_avery', 'sess_test');
    const payload = auth.verify(token);
    expect(payload).not.toBeNull();
    expect(payload.userId).toBe('u_avery');
    expect(payload.sessionId).toBe('sess_test');
  });

  test('verify returns null for tampered token', () => {
    const token = auth.issueToken('u_avery', 'sess_test');
    const tampered = token.slice(0, -4) + 'XXXX';
    expect(auth.verify(tampered)).toBeNull();
  });

  test('verify returns null for null input', () => {
    expect(auth.verify(null)).toBeNull();
    expect(auth.verify('')).toBeNull();
    expect(auth.verify('not.a.token')).toBeNull();
  });

  test('requireAuth sends 401 without token', () => {
    const req = { headers: {}, query: {} };
    const res = {
      statusCode: null,
      body: null,
      status(code) { this.statusCode = code; return this; },
      json(body) { this.body = body; },
    };
    const next = jest.fn();
    auth.requireAuth(req, res, next);
    expect(res.statusCode).toBe(401);
    expect(next).not.toHaveBeenCalled();
  });

  test('requireAuth calls next with valid token', () => {
    const token = auth.issueToken('u_avery', 'sess_test');
    const req = { headers: { authorization: `Bearer ${token}` }, query: {} };
    const res = {};
    const next = jest.fn();
    auth.requireAuth(req, res, next);
    expect(next).toHaveBeenCalled();
    expect(req.auth.userId).toBe('u_avery');
  });
});
