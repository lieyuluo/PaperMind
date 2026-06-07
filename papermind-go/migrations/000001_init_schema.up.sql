-- Tenants table
CREATE TABLE IF NOT EXISTS tenants (
  id UUID PRIMARY KEY,
  name TEXT NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Users table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  username TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'Researcher',
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Papers table
CREATE TABLE IF NOT EXISTS papers (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  title TEXT,
  authors JSONB,
  abstract TEXT,
  file_object_key TEXT,
  status TEXT NOT NULL,
  error_message TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Paper chunks table
CREATE TABLE IF NOT EXISTS paper_chunks (
  id UUID PRIMARY KEY,
  paper_id UUID NOT NULL REFERENCES papers(id),
  chunk_index INT NOT NULL,
  section_name TEXT,
  page_start INT,
  page_end INT,
  content TEXT NOT NULL,
  token_count INT,
  content_hash TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Paper logic models table
CREATE TABLE IF NOT EXISTS paper_logic_models (
  id UUID PRIMARY KEY,
  paper_id UUID NOT NULL REFERENCES papers(id),
  research_problem JSONB,
  core_hypothesis JSONB,
  method_logic JSONB,
  experiment_logic JSONB,
  conclusion_logic JSONB,
  limitation_logic JSONB,
  transferable_ideas JSONB,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Logic nodes table
CREATE TABLE IF NOT EXISTS logic_nodes (
  id UUID PRIMARY KEY,
  paper_id UUID NOT NULL REFERENCES papers(id),
  node_type TEXT NOT NULL,
  content TEXT NOT NULL,
  evidence_chunk_ids JSONB,
  confidence DOUBLE PRECISION,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Logic edges table
CREATE TABLE IF NOT EXISTS logic_edges (
  id UUID PRIMARY KEY,
  paper_id UUID NOT NULL REFERENCES papers(id),
  source_node_id UUID NOT NULL,
  target_node_id UUID NOT NULL,
  relation_type TEXT NOT NULL,
  evidence_chunk_ids JSONB,
  confidence DOUBLE PRECISION,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Workflow runs table
CREATE TABLE IF NOT EXISTS workflow_runs (
  id UUID PRIMARY KEY,
  paper_id UUID,
  workflow_id TEXT NOT NULL,
  workflow_type TEXT NOT NULL,
  status TEXT NOT NULL,
  started_at TIMESTAMP,
  finished_at TIMESTAMP,
  error_message TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Query logs table
CREATE TABLE IF NOT EXISTS query_logs (
  id UUID PRIMARY KEY,
  tenant_id UUID NOT NULL REFERENCES tenants(id),
  question TEXT NOT NULL,
  answer TEXT,
  paper_ids JSONB,
  latency_ms INT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Citations table
CREATE TABLE IF NOT EXISTS citations (
  id UUID PRIMARY KEY,
  query_id UUID NOT NULL REFERENCES query_logs(id),
  paper_id UUID NOT NULL REFERENCES papers(id),
  chunk_id UUID,
  logic_node_id UUID,
  section_name TEXT,
  page_no INT,
  quote TEXT,
  created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Seed data: default tenant
INSERT INTO tenants (id, name, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000001', 'default', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- Seed data: admin user (password: admin123, bcrypt hash)
-- The hash for 'admin123' using bcrypt cost 10
INSERT INTO users (id, tenant_id, username, password_hash, role, created_at, updated_at)
VALUES ('00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'admin', '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy', 'Admin', NOW(), NOW())
ON CONFLICT (username) DO NOTHING;
