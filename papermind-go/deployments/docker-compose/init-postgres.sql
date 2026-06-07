-- Grant CREATEDB privilege to papermind user
-- This is required by Temporal auto-setup which creates its own databases
-- (temporal, temporal_visibility) in the same PostgreSQL instance
ALTER USER papermind CREATEDB;
