-- You-Sir Juan — initial schema
-- Runs automatically on first `docker-compose up postgres`

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Personas / Associate Agent registry
CREATE TABLE IF NOT EXISTS personas (
  user_id       TEXT PRIMARY KEY,
  name          TEXT NOT NULL,
  household     TEXT NOT NULL,
  role          TEXT NOT NULL,
  paradigm      JSONB NOT NULL DEFAULT '{}',
  agent         JSONB NOT NULL DEFAULT '{}',
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- Face enrollment (face_id is a device-computed opaque token)
CREATE TABLE IF NOT EXISTS face_enrollments (
  face_id       TEXT PRIMARY KEY,
  user_id       TEXT REFERENCES personas(user_id) ON DELETE CASCADE,
  display_name  TEXT,
  enrolled_at   TIMESTAMPTZ DEFAULT NOW()
);

-- Session tokens
CREATE TABLE IF NOT EXISTS sessions (
  session_id    TEXT PRIMARY KEY,
  user_id       TEXT REFERENCES personas(user_id) ON DELETE CASCADE,
  token_hash    TEXT NOT NULL,
  issued_at     TIMESTAMPTZ DEFAULT NOW(),
  expires_at    TIMESTAMPTZ NOT NULL
);

-- Conversation memory
CREATE TABLE IF NOT EXISTS memory (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id       TEXT REFERENCES personas(user_id) ON DELETE CASCADE,
  role          TEXT NOT NULL CHECK (role IN ('user','agent','config','training')),
  content       TEXT NOT NULL,
  ts            TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS memory_user_ts ON memory (user_id, ts DESC);

-- Update updated_at trigger
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER personas_updated_at
  BEFORE UPDATE ON personas
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
