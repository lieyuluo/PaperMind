-- Drop tables in reverse dependency order

DROP TABLE IF EXISTS citations;
DROP TABLE IF EXISTS query_logs;
DROP TABLE IF EXISTS workflow_runs;
DROP TABLE IF EXISTS logic_edges;
DROP TABLE IF EXISTS logic_nodes;
DROP TABLE IF EXISTS paper_logic_models;
DROP TABLE IF EXISTS paper_chunks;
DROP TABLE IF EXISTS papers;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS tenants;
