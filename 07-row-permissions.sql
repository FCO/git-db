alter table index enable row level security;
alter table head  enable row level security;

create policy select_files on index for SELECT using (
    owner_id = current_setting('git.logged_user_id')::integer
);

create policy select_head on head for SELECT using (
    user_id = current_setting('git.logged_user_id')::integer
);
