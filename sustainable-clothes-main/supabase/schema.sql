-- Loomtrace MVP schema. Safe to run again in an existing project.
create extension if not exists pgcrypto;
do $$ begin create type public.step_status as enum ('submitted','reviewed','needs_evidence'); exception when duplicate_object then null; end $$;
do $$ begin create type public.app_role as enum ('brand','reviewer'); exception when duplicate_object then null; end $$;
create table if not exists public.user_roles(user_id uuid primary key references auth.users(id) on delete cascade, role public.app_role not null);
create table if not exists public.brands(id uuid primary key default gen_random_uuid(),name text not null,location text,created_at timestamptz not null default now());
create table if not exists public.products(
 id uuid primary key default gen_random_uuid(), brand_id uuid not null references public.brands(id), slug text unique not null,
 name text not null, sku text, image_url text, colorway text, description text,
 materials jsonb not null default '[]'::jsonb, certifications jsonb not null default '[]'::jsonb,
 origin_country text, manufacturing_locations jsonb not null default '[]'::jsonb,
 care_instructions text, repair_instructions text, resale_instructions text, recycling_instructions text,
 is_published boolean not null default false, is_sample boolean not null default true, updated_at timestamptz not null default now()
);
do $$ begin create table public.supply_chain_steps(
 id uuid primary key default gen_random_uuid(), product_id uuid not null references public.products(id) on delete cascade,
 position int not null, title text not null, location text, step_date date, description text,
 status public.step_status not null default 'submitted', evidence_url text, evidence_file_path text,
 reviewed_by text, reviewed_at timestamptz, reviewer_note text, updated_at timestamptz not null default now(),
 unique(product_id,position)
); exception when duplicate_table then null; end $$;
create or replace function public.touch_updated_at() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products for each row execute function public.touch_updated_at();
drop trigger if exists steps_touch_updated_at on public.supply_chain_steps;
create trigger steps_touch_updated_at before update on public.supply_chain_steps for each row execute function public.touch_updated_at();
create or replace function public.enforce_step_review() returns trigger language plpgsql security definer set search_path=public,auth as $$
declare r public.app_role; changed boolean;
begin
 select role into r from public.user_roles where user_id=auth.uid();
 if r='reviewer' then
   if row(new.product_id,new.position,new.title,new.location,new.step_date,new.description,new.evidence_url,new.evidence_file_path)
      is distinct from row(old.product_id,old.position,old.title,old.location,old.step_date,old.description,old.evidence_url,old.evidence_file_path) then
     raise exception 'Reviewers may change review fields only';
   end if;
   if new.status='reviewed' then
     if coalesce(new.evidence_url,'')='' and coalesce(new.evidence_file_path,'')='' then raise exception 'Evidence is required before review'; end if;
     new.reviewed_by=coalesce((select raw_user_meta_data->>'full_name' from auth.users where id=auth.uid()),(select email from auth.users where id=auth.uid()),'Reviewer');
     new.reviewed_at=now();
   elsif new.status='needs_evidence' then
     if coalesce(trim(new.reviewer_note),'')='' then raise exception 'Add a note explaining what evidence is missing'; end if;
     new.reviewed_by=null; new.reviewed_at=null;
   else
     new.reviewed_by=null; new.reviewed_at=null; new.reviewer_note=null;
   end if;
   return new;
 end if;
 if r='brand' then
   if (new.status<>'submitted' and new.status is distinct from old.status) or new.reviewed_by is distinct from old.reviewed_by or new.reviewed_at is distinct from old.reviewed_at or new.reviewer_note is distinct from old.reviewer_note then
     raise exception 'Brand users may only submit steps; reviewer fields are restricted';
   end if;
   changed := row(new.title,new.location,new.step_date,new.description,new.evidence_url,new.evidence_file_path)
       is distinct from row(old.title,old.location,old.step_date,old.description,old.evidence_url,old.evidence_file_path);
   if (changed and old.status='reviewed') or (new.status='submitted' and old.status<>'submitted') then
     new.status='submitted'; new.reviewed_by=null; new.reviewed_at=null; new.reviewer_note=null;
   end if;
   return new;
 end if;
 raise exception 'A brand or reviewer role is required to change a step';
end $$;
drop trigger if exists step_review_guard on public.supply_chain_steps;
create trigger step_review_guard before update on public.supply_chain_steps for each row execute function public.enforce_step_review();
alter table public.user_roles enable row level security;
alter table public.brands enable row level security;
alter table public.products enable row level security;
alter table public.supply_chain_steps enable row level security;
drop policy if exists roles_read_self on public.user_roles;
create policy roles_read_self on public.user_roles for select to authenticated using(user_id=auth.uid());
drop policy if exists brands_public_or_role on public.brands;
create policy brands_public_or_role on public.brands for select to anon,authenticated using(
 exists(select 1 from public.products p where p.brand_id=brands.id and p.is_published=true)
 or exists(select 1 from public.user_roles r where r.user_id=auth.uid())
);
drop policy if exists products_public_published on public.products;
create policy products_public_published on public.products for select to anon,authenticated using(is_published=true or exists(select 1 from public.user_roles r where r.user_id=auth.uid()));
drop policy if exists products_brand_insert on public.products;
create policy products_brand_insert on public.products for insert to authenticated with check(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand'));
drop policy if exists products_brand_update on public.products;
create policy products_brand_update on public.products for update to authenticated using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand')) with check(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand'));
drop policy if exists products_brand_delete on public.products;
create policy products_brand_delete on public.products for delete to authenticated using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand'));
drop policy if exists steps_public_published on public.supply_chain_steps;
create policy steps_public_published on public.supply_chain_steps for select to anon,authenticated using(
 exists(select 1 from public.products p where p.id=product_id and p.is_published=true)
 or exists(select 1 from public.user_roles r where r.user_id=auth.uid())
);
drop policy if exists steps_brand_insert on public.supply_chain_steps;
create policy steps_brand_insert on public.supply_chain_steps for insert to authenticated with check(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand') and status='submitted');
drop policy if exists steps_brand_update on public.supply_chain_steps;
create policy steps_brand_update on public.supply_chain_steps for update to authenticated using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand')) with check(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand'));
drop policy if exists steps_brand_delete on public.supply_chain_steps;
create policy steps_brand_delete on public.supply_chain_steps for delete to authenticated using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='brand'));
drop policy if exists steps_reviewer_update on public.supply_chain_steps;
create policy steps_reviewer_update on public.supply_chain_steps for update to authenticated using(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='reviewer')) with check(exists(select 1 from public.user_roles r where r.user_id=auth.uid() and r.role='reviewer'));
grant usage on schema public to anon,authenticated;
grant select on public.brands,public.products,public.supply_chain_steps to anon,authenticated;
grant select on public.user_roles to authenticated;
revoke update on public.products,public.supply_chain_steps from authenticated;
grant update(name,sku,image_url,colorway,description,materials,certifications,origin_country,manufacturing_locations,care_instructions,repair_instructions,resale_instructions,recycling_instructions,is_published,is_sample) on public.products to authenticated;
grant update(position,title,location,step_date,description,status,evidence_url,evidence_file_path) on public.supply_chain_steps to authenticated;
grant update(status,reviewer_note) on public.supply_chain_steps to authenticated;
grant insert,delete on public.products,public.supply_chain_steps to authenticated;
-- Storage objects are public-read by product design; never upload confidential files.
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('evidence','evidence',true,5242880,array['application/pdf','image/png','image/jpeg','image/webp']),
       ('product-images','product-images',true,5242880,array['image/png','image/jpeg','image/webp'])
on conflict(id) do update set public=true,file_size_limit=5242880,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists public_read_loomtrace_files on storage.objects;
create policy public_read_loomtrace_files on storage.objects for select to anon,authenticated using(bucket_id in ('evidence','product-images'));
drop policy if exists role_upload_loomtrace_files on storage.objects;
create policy role_upload_loomtrace_files on storage.objects for insert to authenticated with check(bucket_id in ('evidence','product-images') and exists(select 1 from public.user_roles r where r.user_id=auth.uid()));
drop policy if exists role_update_loomtrace_files on storage.objects;
create policy role_update_loomtrace_files on storage.objects for update to authenticated using(bucket_id in ('evidence','product-images') and exists(select 1 from public.user_roles r where r.user_id=auth.uid())) with check(bucket_id in ('evidence','product-images') and exists(select 1 from public.user_roles r where r.user_id=auth.uid()));
drop policy if exists role_delete_loomtrace_files on storage.objects;
create policy role_delete_loomtrace_files on storage.objects for delete to authenticated using(bucket_id in ('evidence','product-images') and exists(select 1 from public.user_roles r where r.user_id=auth.uid()));
-- After creating the two Auth users, replace both UUID placeholders and run:
-- insert into public.user_roles(user_id,role) values ('<BRAND_USER_UUID>','brand'),('<REVIEWER_USER_UUID>','reviewer');

