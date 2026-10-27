-- Chan's SUDOKU: Supabase 설정
-- Supabase 대시보드 → SQL Editor → New query 에 이 파일 전체를 붙여 넣고 Run 하세요.
-- 대전·협동 방은 Realtime 채널만 쓰므로 방 테이블은 필요 없습니다. 대전·협동 기록은 scores 에 함께 저장됩니다.
-- 앱을 새 버전으로 올릴 때마다 이 파일 전체를 다시 Run 해도 안전합니다.

-- 1) 기록 테이블 ------------------------------------------------------------
create table if not exists public.scores (
  id             bigint generated always as identity primary key,
  player_secret  uuid        not null,             -- 본인만 아는 아이디 (이름 바꾸기 확인용, 밖으로 공개하지 않음)
  player_public  uuid        not null,             -- 리더보드에 보이는 아이디
  name           text        not null check (char_length(name) between 1 and 16),
  level          smallint    not null check (level between 1 and 8),
  score          integer     not null,             -- 풀이 시간 + (힌트 + 실수) × 30초
  t              integer     not null check (t between 20 and 86400),
  hints          smallint    not null default 0 check (hints between 0 and 99),
  mistakes       smallint    not null default 0 check (mistakes between 0 and 999),
  mode           text        not null check (mode in ('instant', 'grade')),
  lives          smallint    not null default 0 check (lives between 0 and 3),
  hint_limit     smallint    not null default 0 check (hint_limit between 0 and 10),
  seed           bigint,
  created_at     timestamptz not null default now(),
  constraint score_matches check (score = t + (hints + mistakes) * 30)
);

create index if not exists scores_player_level on public.scores (player_public, level, score);

-- 1-1) 대전·협동 기록 (v1.2.0) --------------------------------------------
-- 이미 v1.1 테이블이 있어도 이 파일 전체를 다시 Run 하면 칸만 더해집니다.
alter table public.scores add column if not exists play    text     not null default 'solo';  -- solo / versus / coop
alter table public.scores add column if not exists team    text;                              -- 협동: 참가자 이름들
alter table public.scores add column if not exists players smallint not null default 1;      -- 방 인원

alter table public.scores drop constraint if exists scores_play_check;
alter table public.scores add constraint scores_play_check check (play in ('solo', 'versus', 'coop'));
alter table public.scores drop constraint if exists scores_team_check;
alter table public.scores add constraint scores_team_check check (team is null or char_length(team) <= 80);
alter table public.scores drop constraint if exists scores_players_check;
alter table public.scores add constraint scores_players_check check (players between 1 and 4);

-- 2) 접근 규칙 --------------------------------------------------------------
-- 누구나(로그인 없이) 기록을 추가할 수 있지만, 테이블을 직접 읽거나 고치거나 지울 수는 없습니다.
alter table public.scores enable row level security;

drop policy if exists "anyone can add a score" on public.scores;
create policy "anyone can add a score"
  on public.scores for insert
  to anon, authenticated
  with check (true);

-- 3) 리더보드 보기 (종류·난이도별 최고 기록 + 완성 횟수) --------------------
-- 혼자·대전은 사람별, 협동은 팀(참가자 이름들)별로 묶습니다. player_secret 은 빼고 보여 줍니다.
drop view if exists public.leaderboard;
create view public.leaderboard as
select distinct on (play, who, level)
  player_public, level, name, score, t, hints, mistakes, mode, lives, hint_limit, play, team, players, created_at,
  count(*) over (partition by play, who, level) as solved
from (
  select s.*, case when s.play = 'coop' then coalesce(s.team, s.player_public::text) else s.player_public::text end as who
  from public.scores s
) x
order by play, who, level, score asc, created_at asc;

grant select on public.leaderboard to anon, authenticated;

-- 4) 이름 바꾸기 (본인 비밀 아이디를 아는 경우만) ------------------------------
create or replace function public.rename_player(p_secret uuid, p_name text)
returns void
language sql
security definer
set search_path = public
as $$
  update public.scores
     set name = left(trim(p_name), 16)
   where player_secret = p_secret
     and char_length(trim(p_name)) between 1 and 16;
$$;

revoke all on function public.rename_player(uuid, text) from public;
grant execute on function public.rename_player(uuid, text) to anon, authenticated;

-- 5) 너무 잦은 등록 막기 (같은 사람이 10초 안에 다시 등록하면 거절) -----------
create or replace function public.scores_rate_limit()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if exists (
    select 1 from public.scores
     where player_secret = new.player_secret
       and created_at > now() - interval '10 seconds'
  ) then
    raise exception 'too many submissions';
  end if;
  return new;
end;
$$;

drop trigger if exists scores_rate_limit on public.scores;
create trigger scores_rate_limit
  before insert on public.scores
  for each row execute function public.scores_rate_limit();
