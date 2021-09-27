DO
$do$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles  -- SELECT list can be empty for this
      WHERE  rolname = 'chatwoot') THEN

      CREATE ROLE chatwoot LOGIN PASSWORD 'chatwoot';
   END IF;
END
$do$;

REVOKE CONNECT ON DATABASE chatwoot FROM PUBLIC;

GRANT CONNECT
ON DATABASE chatwoot 
TO chatwoot;

\c chatwoot
create extension if not exists pg_stat_statements;
create extension if not exists pgcrypto;