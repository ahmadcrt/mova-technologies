# MOVA operations notes

## Safety rules for every database stage
1. Export a copy of the data first (below).
2. Run the stage's SQL in the Supabase SQL editor only after the automated tests on GitHub are green.
3. Run the verification query, then do the two-account check on the live site.
4. Keep the stage's rollback script (`supabase/rollbacks/`) ready. A rollback is destructive for that stage's data: export first.
5. Record the result before starting the next stage.

## Backups
- This repository is **public**. Never commit data, exports or backups here, and never upload them as workflow artifacts.
- Now (test data only): in Supabase, open Table Editor, pick each table, and export to CSV. Keep the files in private storage.
- Before real customer data: move to a paid Supabase plan that includes backups, check what it covers (Database, then Backups), and rehearse a restore into a separate test project.
- The schema itself is in `supabase/migrations/`, so it can always be rebuilt.

## Automated checks
- Every push runs: the site checker (`tools/check.py`) and the database tests (`supabase/tests/database/`) on a temporary local Supabase. Nothing in the live project is touched.
- Read results under the repository's Actions tab. A red run means: do not use the migration yet.

## Uploading from a phone
- To create a file in a new folder, use Add file, Create new file, and type the full path with slashes (for example `supabase/rollbacks/001_down.sql`).
- Hidden folders such as `.github` work the same way.
