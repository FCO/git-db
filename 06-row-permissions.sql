create policy select_files on index for ALL using (
    owner_id = current_setting('git.logged_user_id')::integer
);

create policy select_head on head for ALL using (
    user_id = current_setting('jwt.claims.person_id')::integer
);
