-- =============================================================================
-- Redshift Setup Script for dbt AWS SA Demo
-- Run this ONCE as your Redshift admin user (master user or superuser)
-- =============================================================================

-- 1. Create a dedicated database (optional — you can use the default 'dev')
-- CREATE DATABASE ecommerce;

-- 2. Create a dbt service user
CREATE USER dbt_user PASSWORD '<choose-a-strong-password>';

-- 3. Create schemas dbt will manage
-- Platform schemas
CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS staging;
CREATE SCHEMA IF NOT EXISTS intermediate;
CREATE SCHEMA IF NOT EXISTS marts;
-- Mesh consumer schemas
CREATE SCHEMA IF NOT EXISTS marketing;
CREATE SCHEMA IF NOT EXISTS finance;

-- 4. Grant dbt_user access to the dev database
GRANT USAGE ON DATABASE dev TO dbt_user;

-- 5. Grant schema-level permissions
GRANT USAGE, CREATE ON SCHEMA raw          TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA staging      TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA intermediate TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marts        TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA marketing    TO dbt_user;
GRANT USAGE, CREATE ON SCHEMA finance      TO dbt_user;

-- 6. Allow dbt_user to read existing tables (cross-project refs need this)
GRANT SELECT ON ALL TABLES IN SCHEMA raw          TO dbt_user;
GRANT SELECT ON ALL TABLES IN SCHEMA staging      TO dbt_user;
GRANT SELECT ON ALL TABLES IN SCHEMA intermediate TO dbt_user;
GRANT SELECT ON ALL TABLES IN SCHEMA marts        TO dbt_user;
GRANT SELECT ON ALL TABLES IN SCHEMA marketing    TO dbt_user;
GRANT SELECT ON ALL TABLES IN SCHEMA finance      TO dbt_user;

-- 7. Ensure future tables are accessible too (important for incremental models)
ALTER DEFAULT PRIVILEGES IN SCHEMA raw
    GRANT SELECT ON TABLES TO dbt_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA staging
    GRANT SELECT ON TABLES TO dbt_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA intermediate
    GRANT SELECT ON TABLES TO dbt_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA marts
    GRANT SELECT ON TABLES TO dbt_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA marketing
    GRANT SELECT ON TABLES TO dbt_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA finance
    GRANT SELECT ON TABLES TO dbt_user;

-- 8. (Optional) Create a read-only analytics role for BI tools / Bedrock
CREATE ROLE analytics_reader;
GRANT USAGE ON SCHEMA marts     TO ROLE analytics_reader;
GRANT USAGE ON SCHEMA marketing TO ROLE analytics_reader;
GRANT USAGE ON SCHEMA finance   TO ROLE analytics_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA marts     TO ROLE analytics_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA marketing TO ROLE analytics_reader;
GRANT SELECT ON ALL TABLES IN SCHEMA finance   TO ROLE analytics_reader;

-- Attach to a BI user:
-- GRANT ROLE analytics_reader TO USER quicksight_user;

-- =============================================================================
-- Verify setup
-- =============================================================================
SELECT usename, usecreatedb, usesuper FROM pg_user WHERE usename = 'dbt_user';
SELECT nspname FROM pg_namespace WHERE nspname IN ('raw','staging','intermediate','marts');
