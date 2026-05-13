/**
 * Session auth — HMAC-signed session tokens.
 *
 * The token is a base64url-encoded payload + HMAC-SHA256 signature.
 * It contains: { userId, sessionId, iat, exp }.
 *
 * This is NOT JWT — it's a simpler structure that doesn't require
 * a third-party library. Replace with a proper JWT library (jose) in
 * production once the Apple Developer team is set and key rotation is wired.
 *
 * IMPORTANT: set SESSION_SECRET in .env — a long random string.
 * The default below is safe for local dev only.
 */

const crypto = require('crypto');

const SECRET = process.env.SESSION_SECRET || 'ysj-dev-secret-change-before-prod';
const TOKEN_TTL_SECONDS = 8 * 60 * 60; // 8 hours (family kiosk stays signed in for a day)

function sign(payload) {
  const data = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto.createHmac('sha256', SECRET).update(data).digest('base64url');
  return `${data}.${sig}`;
}

function verify(token) {
  if (!token || typeof token !== 'string') return null;
  const [data, sig] = token.split('.');
  if (!data || !sig) return null;
  const expected = crypto.createHmac('sha256', SECRET).update(data).digest('base64url');
  const a = Buffer.from(sig), b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) return null;
  const payload = JSON.parse(Buffer.from(data, 'base64url').toString());
  if (Date.now() / 1000 > payload.exp) return null; // expired
  return payload;
}

function issueToken(userId, sessionId) {
  const now = Math.floor(Date.now() / 1000);
  return sign({ userId, sessionId, iat: now, exp: now + TOKEN_TTL_SECONDS });
}

function requireAuth(req, res, next) {
  const header = req.headers['authorization'] || '';
  const token = header.replace(/^Bearer\s+/i, '').trim()
    || req.query.token;
  const payload = verify(token);
  if (!payload) return res.status(401).json({ error: 'unauthorized' });
  req.auth = payload;
  next();
}

module.exports = { issueToken, verify, requireAuth };
