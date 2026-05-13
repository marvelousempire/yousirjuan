/**
 * Session — POST /api/session
 *
 * The client (iOS or web) performs biometric auth locally, then posts the
 * resolved face_id here. The server returns the full agent_context the
 * client needs to render that user's world:
 *
 *   { sessionId, userId, persona }
 *
 * Token-based sessions and refresh flows are post-MVP. For now, sessionId
 * is opaque and never validated server-side.
 */

const identity = require('./identity');
const personas = require('./personas');

function start(req, res) {
  const { faceId } = req.body || {};

  if (!faceId) {
    return res.status(400).json({ error: 'missing_face_id' });
  }

  const userId = identity.resolveFace(faceId);
  if (!userId) {
    return res.status(404).json({ error: 'unknown_face', faceId });
  }

  const persona = personas.getPersona(userId);
  if (!persona) {
    return res.status(404).json({ error: 'no_persona_for_user', userId });
  }

  const sessionId = `s_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;

  res.json({
    sessionId,
    userId,
    persona,
    issuedAt: new Date().toISOString(),
  });
}

module.exports = { start };
