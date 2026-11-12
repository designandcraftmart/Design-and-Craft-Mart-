-- Run this in Supabase SQL Editor. Public customers can create enquiries/orders,
-- but can never read customer records. Partner authorization is stored in app_metadata.
create extension if not exists pgcrypto;

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  name text not null,
  category text not null,
  description text,
  price numeric(10,2) not null check (price >= 0),
  compare_at_price numeric(10,2),
  images text[] not null default '{}',
  meta_checkout_url text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.chat_sessions (
  id uuid primary key default gen_random_uuid(),
  token text unique not null,
  product_id uuid references public.products(id) on delete set null,
  customer_name text not null,
  mobile text not null,
  email text not null,
  consent_at timestamptz not null,
  status text not null default 'open' check (status in ('open','assigned','accepted','closed')),
  assigned_to uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now()
);
create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  session_id uuid not null references public.chat_sessions(id) on delete cascade,
  sender_type text not null check (sender_type in ('customer','partner','system')),
  sender_id uuid references auth.users(id) on delete set null,
  body text not null,
  created_at timestamptz not null default now()
);
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  session_id uuid references public.chat_sessions(id) on delete set null,
  product_id uuid references public.products(id) on delete set null,
  customer_name text,
  mobile text,
  email text,
  quantity integer not null default 1 check (quantity > 0),
  regular_price numeric(10,2),
  final_price numeric(10,2),
  status text not null default 'pending' check (status in ('pending','confirmed','completed','cancelled')),
  assigned_to uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table if not exists public.partner_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role in ('admin','product_manager','order_processor','view_only')),
  created_at timestamptz not null default now()
);

-- Authorization reads trusted app_metadata JWT claims, never user-editable user_metadata.
-- Set app_metadata.role to admin/product_manager/order_processor/view_only for invited partners.
create or replace function public.current_partner_role()
returns text language sql stable security invoker set search_path = '' as $$
  select coalesce((select auth.jwt() -> 'app_metadata' ->> 'role'), 'customer');
$$;
create or replace function public.is_partner()
returns boolean language sql stable security invoker set search_path = '' as $$
  select public.current_partner_role() in ('admin','product_manager','order_processor','view_only');
$$;

alter table public.products enable row level security;
alter table public.chat_sessions enable row level security;
alter table public.chat_messages enable row level security;
alter table public.orders enable row level security;
alter table public.partner_roles enable row level security;

create policy "Public can view active products" on public.products for select to anon, authenticated using (is_active = true or public.is_partner());
create policy "Product managers manage products" on public.products for all to authenticated using (public.current_partner_role() in ('admin','product_manager')) with check (public.current_partner_role() in ('admin','product_manager'));
create policy "Anyone can create a chat enquiry" on public.chat_sessions for insert to anon, authenticated with check (consent_at is not null and length(customer_name) between 2 and 120 and length(mobile) between 7 and 30 and length(email) <= 254);
create policy "Partners view chat sessions" on public.chat_sessions for select to authenticated using (public.is_partner());
create policy "Order staff update chat sessions" on public.chat_sessions for update to authenticated using (public.current_partner_role() in ('admin','order_processor')) with check (public.current_partner_role() in ('admin','order_processor'));
create policy "Customers can send first message" on public.chat_messages for insert to anon, authenticated with check (sender_type in ('customer','system'));
create policy "Partners read chat messages" on public.chat_messages for select to authenticated using (public.is_partner());
create policy "Partners reply to chat" on public.chat_messages for insert to authenticated with check (public.is_partner() and sender_type = 'partner' and sender_id = (select auth.uid()));
create policy "Anyone can create order request" on public.orders for insert to anon, authenticated with check (status = 'pending');
create policy "Partners view orders" on public.orders for select to authenticated using (public.is_partner());
create policy "Order staff update orders" on public.orders for update to authenticated using (public.current_partner_role() in ('admin','order_processor')) with check (public.current_partner_role() in ('admin','order_processor'));
create policy "Users can view own partner role" on public.partner_roles for select to authenticated using (user_id = (select auth.uid()));
create policy "Only admins manage partner roles" on public.partner_roles for all to authenticated using (public.current_partner_role() = 'admin') with check (public.current_partner_role() = 'admin');

grant select on public.products to anon, authenticated;
grant insert on public.chat_sessions to anon, authenticated;
grant select, update on public.chat_sessions to authenticated;
grant insert, select on public.chat_messages to anon, authenticated;
grant insert on public.orders to anon, authenticated;
grant select, update on public.orders to authenticated;
grant select on public.partner_roles to authenticated;

insert into public.products (slug,name,category,description,price,compare_at_price,images,is_active) values
('custom-photo-frame','Custom Photo Frame','Photo Frames','A personalised photo frame made to display a favourite memory.',349,499,array['/images/photo-frame.jpg'],true),
('custom-mug','Custom Mug','Mugs','A custom printed mug for everyday moments.',299,399,array['/images/mug.jpg'],true),
('personalised-glass','Personalised Glass','Glasses','A personalised glass with your chosen photo or artwork.',299,399,array['/images/glass.jpg'],true),
('custom-t-shirt','Custom T-Shirt','T-Shirts','A custom printed T-shirt. Share your design idea before ordering.',499,699,array['/images/tshirt.jpg'],true),
('personalised-gift-set','Personalised Gift Set','Gift Sets','A thoughtful gift set with personalised items.',899,1299,array['/images/gift-set.jpg'],true),
('custom-gift','Custom Gift','Personalised Gifts','A personalised gift prepared around your idea.',599,799,array['/images/gift.jpg'],true)
on conflict (slug) do nothing;
