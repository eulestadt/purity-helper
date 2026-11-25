-- Purity Help sync schema. Safe to run more than once.

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id TEXT UNIQUE,
  email TEXT UNIQUE,
  password_hash TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_versions (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  version BIGINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS sync_clients (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  client_id TEXT NOT NULL,
  last_mutation_id BIGINT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, client_id)
);

CREATE TABLE IF NOT EXISTS documents (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  key TEXT NOT NULL,
  value JSONB,
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  version BIGINT NOT NULL,
  PRIMARY KEY (user_id, key)
);

CREATE TABLE IF NOT EXISTS document_changes (
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  version BIGINT NOT NULL,
  key TEXT NOT NULL,
  value JSONB,
  deleted BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY (user_id, version)
);

CREATE INDEX IF NOT EXISTS idx_document_changes_user_version
  ON document_changes (user_id, version);

CREATE TABLE IF NOT EXISTS share_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token UUID NOT NULL UNIQUE DEFAULT gen_random_uuid(),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE (user_id)
);

CREATE INDEX IF NOT EXISTS idx_share_tokens_token ON share_tokens (token);

CREATE TABLE IF NOT EXISTS password_reset_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used BOOLEAN NOT NULL DEFAULT FALSE,
  attempts INT NOT NULL DEFAULT 0
);

ALTER TABLE password_reset_tokens ADD COLUMN IF NOT EXISTS attempts INT NOT NULL DEFAULT 0;

CREATE INDEX IF NOT EXISTS idx_prt_user_id ON password_reset_tokens (user_id);
