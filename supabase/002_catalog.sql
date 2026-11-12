-- Run AFTER schema.sql, in Supabase > SQL Editor. Safe to run more than once.
-- Adds what the website needs to list products from the database.

alter table public.products add column if not exists is_featured boolean not null default false;
alter table public.products add column if not exists sort_order integer not null default 0;

create index if not exists products_active_sort_idx on public.products (is_active, sort_order);

-- Keep updated_at correct whenever a product row changes.
create or replace function public.touch_updated_at()
returns trigger language plpgsql security invoker set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at before update on public.products
  for each row execute function public.touch_updated_at();

-- Show the six starter products as Bestsellers, in a fixed order.
update public.products set is_featured = true, sort_order = v.ord
from (values
  ('custom-photo-frame', 1), ('custom-mug', 2), ('personalised-glass', 3),
  ('custom-t-shirt', 4), ('personalised-gift-set', 5), ('custom-gift', 6)
) as v(slug, ord)
where public.products.slug = v.slug;
