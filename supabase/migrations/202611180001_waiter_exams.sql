-- Qarson imtahanı: 4 variantlı test, 80% keçid həddi.
create table if not exists public.exam_tests (
 id uuid primary key default gen_random_uuid(),
 title text not null,
 description text,
 duration_minutes integer not null default 20 check (duration_minutes between 0 and 240),
 pass_percent integer not null default 80 check (pass_percent=80),
 is_published boolean not null default false,
 created_by uuid not null references auth.users(id) on delete cascade,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
create table if not exists public.exam_questions (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exam_tests(id) on delete cascade,
 question_text text not null,
 option_a text not null, option_b text not null, option_c text not null, option_d text not null,
 correct_option text not null check (correct_option in ('A','B','C','D')),
 points integer not null default 1 check (points between 1 and 100),
 sort_order integer not null default 0,
 created_at timestamptz not null default now()
);
create table if not exists public.exam_attempts (
 id uuid primary key default gen_random_uuid(),
 exam_id uuid not null references public.exam_tests(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 score integer not null,
 total_points integer not null,
 percentage numeric(5,2) not null,
 passed boolean not null,
 correct_count integer not null,
 wrong_count integer not null,
 created_at timestamptz not null default now()
);
create table if not exists public.exam_answers (
 id uuid primary key default gen_random_uuid(),
 attempt_id uuid not null references public.exam_attempts(id) on delete cascade,
 question_id uuid not null references public.exam_questions(id) on delete cascade,
 selected_option text check (selected_option in ('A','B','C','D')),
 is_correct boolean not null,
 awarded_points integer not null default 0,
 unique(attempt_id,question_id)
);
alter table public.exam_tests enable row level security;
alter table public.exam_questions enable row level security;
alter table public.exam_attempts enable row level security;
alter table public.exam_answers enable row level security;
create or replace function public.rc_is_admin() returns boolean language sql stable security definer set search_path=public as $$
 select lower(coalesce(auth.jwt()->>'email',''))='unvan.premium@gmail.com'
 and exists(select 1 from public.profiles p where p.id=auth.uid() and p.role='admin');
$$;
drop policy if exists "exam_tests_read" on public.exam_tests;
create policy "exam_tests_read" on public.exam_tests for select to authenticated using (public.rc_is_admin() or is_published=true);
drop policy if exists "exam_tests_admin_insert" on public.exam_tests;
create policy "exam_tests_admin_insert" on public.exam_tests for insert to authenticated with check (public.rc_is_admin() and created_by=auth.uid());
drop policy if exists "exam_tests_admin_update" on public.exam_tests;
create policy "exam_tests_admin_update" on public.exam_tests for update to authenticated using (public.rc_is_admin()) with check (public.rc_is_admin());
drop policy if exists "exam_tests_admin_delete" on public.exam_tests;
create policy "exam_tests_admin_delete" on public.exam_tests for delete to authenticated using (public.rc_is_admin());
drop policy if exists "exam_questions_admin_all" on public.exam_questions;
create policy "exam_questions_admin_all" on public.exam_questions for all to authenticated using (public.rc_is_admin()) with check (public.rc_is_admin());
drop policy if exists "exam_attempts_read_own_or_admin" on public.exam_attempts;
create policy "exam_attempts_read_own_or_admin" on public.exam_attempts for select to authenticated using (user_id=auth.uid() or public.rc_is_admin());
drop policy if exists "exam_answers_read_own_or_admin" on public.exam_answers;
create policy "exam_answers_read_own_or_admin" on public.exam_answers for select to authenticated using (exists(select 1 from public.exam_attempts a where a.id=attempt_id and (a.user_id=auth.uid() or public.rc_is_admin())));
grant select,insert,update,delete on public.exam_tests,public.exam_questions to authenticated;
grant select on public.exam_attempts,public.exam_answers to authenticated;
create or replace function public.get_exam_questions(p_exam_id uuid)
returns table(id uuid,question_text text,option_a text,option_b text,option_c text,option_d text,points integer)
language plpgsql security definer set search_path=public as $$
begin
 if auth.uid() is null then raise exception 'Giriş tələb olunur'; end if;
 if not exists(select 1 from public.exam_tests e where e.id=p_exam_id and (e.is_published or public.rc_is_admin())) then raise exception 'İmtahan mövcud deyil'; end if;
 return query select q.id,q.question_text,q.option_a,q.option_b,q.option_c,q.option_d,q.points from public.exam_questions q where q.exam_id=p_exam_id order by q.sort_order,q.created_at;
end; $$;
create or replace function public.submit_exam_attempt(p_answers jsonb)
returns jsonb language plpgsql security definer set search_path=public as $$
declare v_exam_id uuid; v_attempt_id uuid; v_score integer:=0; v_total integer:=0; v_correct integer:=0; v_wrong integer:=0; v_count integer:=0; v_pct numeric(5,2); v_pass boolean;
 v_item jsonb; v_q public.exam_questions%rowtype; v_selected text; v_awarded integer;
begin
 if auth.uid() is null then raise exception 'Giriş tələb olunur'; end if;
 if jsonb_typeof(p_answers)<>'array' or jsonb_array_length(p_answers)=0 then raise exception 'Cavablar boşdur'; end if;
 select q.exam_id into v_exam_id from public.exam_questions q where q.id=(p_answers->0->>'question_id')::uuid;
 if v_exam_id is null then raise exception 'İmtahan tapılmadı'; end if;
 if not exists(select 1 from public.exam_tests e where e.id=v_exam_id and (e.is_published or public.rc_is_admin())) then raise exception 'İmtahan bağlıdır'; end if;
 insert into public.exam_attempts(exam_id,user_id,score,total_points,percentage,passed,correct_count,wrong_count) values(v_exam_id,auth.uid(),0,0,0,false,0,0) returning id into v_attempt_id;
 for v_item in select * from jsonb_array_elements(p_answers) loop
  select * into v_q from public.exam_questions where id=(v_item->>'question_id')::uuid and exam_id=v_exam_id;
  if not found then raise exception 'Yanlış sual'; end if;
  v_selected:=upper(coalesce(v_item->>'selected_option',''));
  if v_selected not in ('A','B','C','D') then v_selected:=null; end if;
  v_total:=v_total+v_q.points; v_count:=v_count+1; v_awarded:=0;
  if v_selected=v_q.correct_option then v_awarded:=v_q.points;v_score:=v_score+v_awarded;v_correct:=v_correct+1;else v_wrong:=v_wrong+1;end if;
  insert into public.exam_answers(attempt_id,question_id,selected_option,is_correct,awarded_points) values(v_attempt_id,v_q.id,v_selected,v_selected=v_q.correct_option,v_awarded);
 end loop;
 if v_total=0 then raise exception 'Sual balları sıfırdır'; end if;
 v_pct:=round((v_score::numeric/v_total)*100,2);v_pass:=v_pct>=80;
 update public.exam_attempts set score=v_score,total_points=v_total,percentage=v_pct,passed=v_pass,correct_count=v_correct,wrong_count=v_wrong where id=v_attempt_id;
 return jsonb_build_object('attempt_id',v_attempt_id,'score',v_score,'total_points',v_total,'percentage',v_pct,'passed',v_pass,'correct_count',v_correct,'wrong_count',v_wrong,'question_count',v_count);
end; $$;
revoke all on function public.get_exam_questions(uuid) from public;
revoke all on function public.submit_exam_attempt(jsonb) from public;
grant execute on function public.get_exam_questions(uuid) to authenticated;
grant execute on function public.submit_exam_attempt(jsonb) to authenticated;
