-- =============================================================================
-- ACID - Core Database Schema
-- =============================================================================
-- This runs FIRST when PostgreSQL container starts
-- Creates all required tables and structures
-- =============================================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =============================================================================
-- USERS TABLE (Authentication)
-- =============================================================================
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(30) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255),
    role VARCHAR(20) DEFAULT 'user' CHECK (role IN ('user', 'admin', 'service')),
    
    email_verified BOOLEAN DEFAULT false,
    verification_token VARCHAR(255),
    verification_expires_at TIMESTAMP,
    
    reset_token VARCHAR(255),
    reset_expires_at TIMESTAMP,
    
    api_key VARCHAR(255),
    last_login_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_verification_token ON users(verification_token) WHERE verification_token IS NOT NULL;
CREATE INDEX idx_users_reset_token ON users(reset_token) WHERE reset_token IS NOT NULL;

-- =============================================================================
-- SESSIONS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(32) PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    refresh_token_hash VARCHAR(255) NOT NULL,
    user_agent TEXT,
    ip_address VARCHAR(45),
    device_name VARCHAR(255),
    revoked BOOLEAN DEFAULT false,
    expires_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_expiry CHECK (expires_at > created_at)
);

CREATE INDEX idx_sessions_user_id ON sessions(user_id);
CREATE INDEX idx_sessions_refresh_token ON sessions(refresh_token_hash);
CREATE INDEX idx_sessions_expires ON sessions(expires_at) WHERE NOT revoked;
CREATE INDEX idx_sessions_active ON sessions(user_id, expires_at) WHERE NOT revoked;

-- =============================================================================
-- API KEYS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS api_keys (
    id VARCHAR(32) PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    key_hash VARCHAR(255) UNIQUE NOT NULL,
    key_prefix VARCHAR(16) NOT NULL,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    scopes JSONB DEFAULT '["read"]'::jsonb,
    rate_limit INTEGER DEFAULT 1000,
    revoked BOOLEAN DEFAULT false,
    last_used_at TIMESTAMP,
    expires_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    CONSTRAINT valid_rate_limit CHECK (rate_limit > 0 AND rate_limit <= 50000)
);

CREATE INDEX idx_api_keys_user_id ON api_keys(user_id);
CREATE INDEX idx_api_keys_hash ON api_keys(key_hash) WHERE NOT revoked;
CREATE INDEX idx_api_keys_prefix ON api_keys(key_prefix);

-- =============================================================================
-- AUDIT LOGS TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
    api_key_id VARCHAR(32) REFERENCES api_keys(id) ON DELETE SET NULL,
    action VARCHAR(50) NOT NULL,
    resource VARCHAR(100),
    resource_id VARCHAR(255),
    ip_address VARCHAR(45),
    user_agent TEXT,
    success BOOLEAN DEFAULT true,
    error_message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id, created_at DESC);
CREATE INDEX idx_audit_logs_action ON audit_logs(action, created_at DESC);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at DESC);

-- =============================================================================
-- RATE LIMIT ENTRIES TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS rate_limit_entries (
    id SERIAL PRIMARY KEY,
    identifier VARCHAR(255) NOT NULL,
    endpoint VARCHAR(100),
    window_start TIMESTAMP NOT NULL,
    request_count INTEGER DEFAULT 1,
    CONSTRAINT unique_rate_limit UNIQUE (identifier, endpoint, window_start)
);

CREATE INDEX idx_rate_limit_lookup ON rate_limit_entries(identifier, endpoint, window_start);

-- =============================================================================
-- CATEGORIES TABLE (Employee Positions/Tags)
-- =============================================================================
CREATE TABLE IF NOT EXISTS categories (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    color VARCHAR(20) DEFAULT '#3b82f6',
    entity_type VARCHAR(50) NOT NULL DEFAULT 'employee',
    icon VARCHAR(50),
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    created_by INTEGER REFERENCES users(id),
    is_active BOOLEAN DEFAULT true
);

CREATE INDEX idx_categories_entity_type ON categories(entity_type);
CREATE INDEX idx_categories_is_active ON categories(is_active);

-- =============================================================================
-- ENTITY-CATEGORIES JUNCTION TABLE
-- =============================================================================
CREATE TABLE IF NOT EXISTS entity_categories (
    id SERIAL PRIMARY KEY,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER NOT NULL,
    category_id INTEGER NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
    assigned_at TIMESTAMP DEFAULT NOW(),
    assigned_by INTEGER REFERENCES users(id),
    UNIQUE(entity_type, entity_id, category_id)
);

CREATE INDEX idx_entity_categories_entity ON entity_categories(entity_type, entity_id);
CREATE INDEX idx_entity_categories_category ON entity_categories(category_id);

-- =============================================================================
-- HELPER FUNCTIONS
-- =============================================================================
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

CREATE TRIGGER update_api_keys_updated_at
    BEFORE UPDATE ON api_keys
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at();

-- =============================================================================
-- DEFAULT CATEGORIES (Employee Positions)
-- =============================================================================
INSERT INTO categories (name, description, color, entity_type, icon) VALUES
    ('Full Stack Developer', 'Works on both frontend and backend', '#8b5cf6', 'employee', '💻'),
    ('Frontend Developer', 'Specializes in UI/UX and frontend frameworks', '#3b82f6', 'employee', '🎨'),
    ('Backend Developer', 'Server-side development and APIs', '#10b981', 'employee', '⚙️'),
    ('DevOps Engineer', 'Infrastructure and deployment automation', '#f59e0b', 'employee', '🚀'),
    ('Data Engineer', 'Data pipelines and processing', '#ec4899', 'employee', '📊'),
    ('Machine Learning Engineer', 'AI/ML model development', '#8b5cf6', 'employee', '🤖'),
    ('Project Manager', 'Manages project timelines and teams', '#14b8a6', 'employee', '📋'),
    ('Tech Lead', 'Technical leadership and mentoring', '#f97316', 'employee', '👔'),
    ('QA Engineer', 'Quality assurance and testing', '#22c55e', 'employee', '✅'),
    ('Database Administrator', 'Database management and optimization', '#0ea5e9', 'employee', '🗄️')
ON CONFLICT (name) DO NOTHING;

-- =============================================================================
-- DEFAULT ADMIN USER (change password after first login!)
-- =============================================================================
-- Password: Admin@2026 (bcrypt $2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.flLWrYLYfCDVGS)
INSERT INTO users (email, username, password_hash, name, role, email_verified) VALUES
    ('admin@acid.local', 'admin', '$2a$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/X4.flLWrYLYfCDVGS', 'Administrator', 'admin', true)
ON CONFLICT (email) DO NOTHING;

-- Grant permissions
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA PUBLIC TO acid;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA PUBLIC TO acid;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA PUBLIC TO acid;

DO $$
BEGIN
    RAISE NOTICE 'ACID database schema initialized successfully!';
END $$;