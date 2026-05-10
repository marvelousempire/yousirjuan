CREATE TABLE workspaces (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE namespaces (
  id UUID PRIMARY KEY,
  workspace_id UUID REFERENCES workspaces(id),
  name TEXT NOT NULL,
  policy JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE assistants (
  id UUID PRIMARY KEY,
  namespace_id UUID REFERENCES namespaces(id),
  type TEXT NOT NULL,
  version TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE memory_records (
  id UUID PRIMARY KEY,
  namespace_id UUID REFERENCES namespaces(id),
  source_type TEXT,
  content TEXT,
  metadata JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE audit_logs (
  id UUID PRIMARY KEY,
  namespace_id UUID REFERENCES namespaces(id),
  event_type TEXT,
  payload JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE orchestration_jobs (
  id UUID PRIMARY KEY,
  namespace_id UUID REFERENCES namespaces(id),
  workflow TEXT,
  status TEXT,
  payload JSONB,
  created_at TIMESTAMP DEFAULT NOW()
);
