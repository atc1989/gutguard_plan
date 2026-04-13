-- Example seed script for the directory tables introduced in supabase-schema.sql.
-- Replace the placeholder UUIDs and names with your real users and structure.

-- 1. Create one organization.
insert into organizations (name, code)
values ('Gutguard', 'gutguard-main')
on conflict (code) do update
set name = excluded.name;

-- 2. Create one O1, one platoon, one squad, and one team in the same chain.
with org as (
  select id
  from organizations
  where code = 'gutguard-main'
),
o1_unit as (
  insert into teams (organization_id, parent_team_id, unit_type, name, code)
  select org.id, null, 'o1', 'Davao O1', 'dvo-o1'
  from org
  on conflict do nothing
  returning id, organization_id
),
o1_existing as (
  select id, organization_id
  from teams
  where code = 'dvo-o1'
),
o1_final as (
  select id, organization_id from o1_unit
  union all
  select id, organization_id from o1_existing
  limit 1
),
platoon_unit as (
  insert into teams (organization_id, parent_team_id, unit_type, name, code)
  select o1_final.organization_id, o1_final.id, 'platoon', 'Platoon Alpha', 'platoon-alpha'
  from o1_final
  on conflict do nothing
  returning id, organization_id
),
platoon_existing as (
  select id, organization_id
  from teams
  where code = 'platoon-alpha'
),
platoon_final as (
  select id, organization_id from platoon_unit
  union all
  select id, organization_id from platoon_existing
  limit 1
),
squad_unit as (
  insert into teams (organization_id, parent_team_id, unit_type, name, code)
  select platoon_final.organization_id, platoon_final.id, 'squad', 'Squad One', 'squad-one'
  from platoon_final
  on conflict do nothing
  returning id, organization_id
),
squad_existing as (
  select id, organization_id
  from teams
  where code = 'squad-one'
),
squad_final as (
  select id, organization_id from squad_unit
  union all
  select id, organization_id from squad_existing
  limit 1
),
team_unit as (
  insert into teams (organization_id, parent_team_id, unit_type, name, code)
  select squad_final.organization_id, squad_final.id, 'team', 'Team Spark', 'team-spark'
  from squad_final
  on conflict do nothing
  returning id, organization_id
)
select 1;

-- 3. Link users to the correct unit in the chain.
-- Replace the placeholder auth user UUIDs below.
with org as (
  select id
  from organizations
  where code = 'gutguard-main'
),
o1_team as (
  select id
  from teams
  where code = 'dvo-o1'
),
platoon_team as (
  select id
  from teams
  where code = 'platoon-alpha'
),
squad_team as (
  select id
  from teams
  where code = 'squad-one'
),
member_team as (
  select id
  from teams
  where code = 'team-spark'
)
insert into user_team_memberships (user_id, organization_id, team_id)
select *
from (
  select '00000000-0000-0000-0000-000000000001'::uuid as user_id, org.id as organization_id, member_team.id as team_id
  from org, member_team
  union all
  select '00000000-0000-0000-0000-000000000002'::uuid, org.id, member_team.id
  from org, member_team
  union all
  select '00000000-0000-0000-0000-000000000003'::uuid, org.id, squad_team.id
  from org, squad_team
  union all
  select '00000000-0000-0000-0000-000000000004'::uuid, org.id, platoon_team.id
  from org, platoon_team
  union all
  select '00000000-0000-0000-0000-000000000005'::uuid, org.id, o1_team.id
  from org, o1_team
) seed_rows
on conflict (user_id, team_id) do nothing;

-- Mapping example:
-- user 000...001 = member in Team Spark
-- user 000...002 = leader in Team Spark
-- user 000...003 = squad leader in Squad One
-- user 000...004 = platoon leader in Platoon Alpha
-- user 000...005 = O1 leader in Davao O1
