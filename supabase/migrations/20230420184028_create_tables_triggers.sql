create table public.userprofile (
    userid uuid primary key references auth.users on delete cascade,
    email text not null
);

create table public.accounts (
    id uuid primary key default uuid_generate_v4(),
    ownerid uuid references public.userprofile on delete cascade
);

create table public.accounts_users (
    userid uuid references public.userprofile on delete cascade,
    accountid uuid references public.accounts on delete cascade
);

-- enable RLS
alter table public.userprofile enable row level security;
alter table public.accounts enable row level security;
alter table public.accounts_users enable row level security;

-- function to save user info to other tables
create or replace function public.handle_new_user()
returns trigger
language plpgsql 
security definer set search_path = public
as $$
begin
	WITH userprofile AS (
		insert into public.userprofile (userid, email)
		values (new.id, new.email)
		returning userid
	),
	accounts AS (
		insert into public.accounts (ownerid)
		select userprofile.userid from userprofile
		returning id  
	) 
	insert into public.accounts_users (userid, accountid) 
		select userprofile.userid, accounts.id from userprofile, accounts;
	return new;
end;
$$;

-- trigger to add profile info when a signup happens
create trigger on_auth_user_created
	after insert on auth.users
	for each row execute procedure public.handle_new_user();
