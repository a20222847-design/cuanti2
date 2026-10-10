-- Ejecutar una sola vez en Supabase > SQL Editor.
-- La app solo puede insertar respuestas mediante la llave pública.

create table if not exists public.survey_responses_v2 (
  response_id text primary key,
  submitted_at_utc timestamptz not null,
  app_version text not null,
  condition_message text not null check (condition_message in ('responsabilidad', 'causa_comun')),
  item_order text not null,
  consent text not null,
  adult text not null,
  university_student text not null,
  class_format text not null,
  group_frequency text not null,
  coordination_channel text not null,
  item_notes text not null,
  item_voice text not null,
  item_exposure text not null,
  item_emotional text not null,
  item_no_rotation text not null,
  item_leadership text not null,
  item_rotate text not null,
  item_ask text not null,
  scale_answered integer not null,
  acceptance_index numeric,
  intervention_intent text not null,
  reaction text not null,
  reaction_other text,
  message_recall text not null,
  message_recall_correct boolean not null,
  perceived_topic text,
  participant_gender text not null,
  age_group text not null,
  study_cycle text not null,
  study_area text not null,
  duration_seconds integer not null,
  created_at timestamptz not null default now()
);

-- Compatibilidad con tablas piloto creadas antes de la versión 2.1.0.
alter table public.survey_responses_v2
  add column if not exists coordination_channel text;

alter table public.survey_responses_v2 enable row level security;

revoke all on table public.survey_responses_v2 from anon, authenticated;
grant insert on table public.survey_responses_v2 to anon;

drop policy if exists "anonymous_insert_only_v2" on public.survey_responses_v2;
create policy "anonymous_insert_only_v2"
on public.survey_responses_v2
for insert
to anon
with check (true);
