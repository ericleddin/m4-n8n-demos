-- 1) Vektorstore (Standard n8n/Supabase LangChain Setup, Dimension 1536)
create extension if not exists vector;

create table if not exists documents (
  id        uuid primary key default gen_random_uuid(),
  content   text,
  metadata  jsonb,
  embedding vector(1536)
);

create or replace function match_documents (
  query_embedding vector(1536),
  match_count int default null,
  filter jsonb default '{}'
) returns table (id uuid, content text, metadata jsonb, similarity float)
language plpgsql as $$
begin
  return query
  select id, content, metadata,
         1 - (documents.embedding <=> query_embedding) as similarity
  from documents
  where metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
end; $$;

-- 2) Bestellungen (API-Tool)
create table if not exists orders (
  order_number       text primary key,
  customer_name      text not null,
  status             text not null,
  items              text not null,
  order_date         date not null,
  estimated_delivery date,
  tracking_number    text
);

insert into orders (order_number, customer_name, status, items, order_date, estimated_delivery, tracking_number) values
('VB-10001','Anna Becker','Versandt','Voltbox Pro 800','2026-06-18','2026-06-23','DHL-00347711992'),
('VB-10002','Tomas Richter','In Bearbeitung','Voltbox Max 1500, Erweiterungsakku','2026-06-21','2026-06-27',null),
('VB-10003','Sarah Vogt','Zugestellt','Solarpanel SP200','2026-06-10','2026-06-13','DHL-00347655120'),
('VB-10004','Mehmet Yildiz','Versandt','Voltbox Mini 300','2026-06-20','2026-06-24','DHL-00347788431'),
('VB-10005','Laura Koenig','Storniert','Voltbox Pro 800','2026-06-15',null,null),
('VB-10006','Jonas Wolf','In Bearbeitung','Solarpanel SP100, KFZ-Ladekabel','2026-06-22','2026-06-26',null),
('VB-10007','Petra Hofmann','Zugestellt','Voltbox Max 1500','2026-05-30','2026-06-04','SPEDITION-55012')
on conflict (order_number) do nothing;

-- 3) Tickets (Action-Tool)
create table if not exists tickets (
  id             bigint generated always as identity primary key,
  created_at     timestamptz not null default now(),
  customer_email text,
  order_number   text,
  subject        text not null,
  message        text not null,
  status         text not null default 'offen'
);
