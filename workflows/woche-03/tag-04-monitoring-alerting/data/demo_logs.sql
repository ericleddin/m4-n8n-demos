-- Tabelle für Demo A (Logging & Kosten-Tracking).
-- In Supabase unter SQL Editor ausführen, bevor der Workflow läuft.
CREATE TABLE demo_logs (
  id bigint generated always as identity primary key,
  timestamp timestamptz not null default now(),
  node_name text,
  status text,
  duration_ms integer,
  tokens_used integer,
  error_message text
);
