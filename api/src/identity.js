/**
 * Identity layer — face_id → user_id + enrollment.
 *
 * Face IDs are opaque tokens computed on-device (SHA-256 of face landmark
 * data + enrollment timestamp). The server never sees raw biometric data.
 *
 * Production: backed by Postgres `face_enrollments` table.
 * MVP: in-memory seed for the founding four Associates.
 */

const faceIndex = new Map([
  ['face-avery-001',    'u_avery'],
  ['face-bobby-001',    'u_bobby'],
  ['face-nivram-001',   'u_nivram'],
  ['face-yousirjuan-001', 'u_yousirjuan'],
]);

function resolveFace(faceId) {
  return faceIndex.get(faceId) || null;
}

function listEnrolledFaces() {
  return Array.from(faceIndex.entries()).map(([faceId, userId]) => ({ faceId, userId }));
}

function registerFace(faceId, userId) {
  faceIndex.set(faceId, userId);
}

module.exports = { resolveFace, listEnrolledFaces, registerFace };
