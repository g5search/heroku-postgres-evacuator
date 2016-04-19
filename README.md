## Heroku Postgres Evacuator

This is a containerized tool for dealing with moving databases out of Heroku Postgres. It includes scripts that can import Heroku PG data to another source, and a script that can completely remove a database from Heroku PG and repoint the app. This is *not* the default action.

By default, the `import.sh` script is run. This requires a number of environment variables to be set. The scripts aren't rocket science.

You can tell the container to run the `move.sh` script, which is dangerous. It's not irreversible, because there is also a `rollback.sh` script that will take the backed-up data and recreate things on Heroku. There is no way to alter the heroku `DATABASE_URL` while any database plan is still associated with the app, which means I have to delete the database plan. Scary. I will delete *every database plan*, even ones that are not the primary plan (again, required to change `DATABASE_URL`), but I will only capture a backup of the primary database. This means if you are doing something funky, like stashing a database for later, it might be eaten and never return. This script will put the app in maintenance mode for the duration of the database activity. This script requires some S3 keys so that a final backup can be made.

In my testing, even if you delete a database plan, the PGBackups in heroku remain. I have no idea why or how, but that does provide a minor amount of safety.

Both scripts share the `CLEAN_TARGET` variable.  When `true`, it tells the restore command to add the `--clean` flag. This will drop objects before creating them, which might be desirable when you've done a database migration once, tested it, and are about to go into production. You have to consider if some objects have been removed from the source since you last migrated, because those objects will remain on the target. In that case you might be better off recreating the target database to ensure it's clean (and then, ironically, you don't need this flag at all!).

The `import.sh` also has `SKIP_SNAPSHOT=true` if you don't need to take a new snapshot in Heroku. It will skip that step and instead use the URL of the most recent backup.

### Important Note on Usage

Unfortunately, the Heroku CLI that this depends upon has an auto-update facility that explodes quite frequently when the CLI baked into this image is out-of-date. Like, really frequently. As in this image becomes useless in a matter of days. Until they [address this issue](https://github.com/heroku/heroku-cli/issues/129), you're going to continue to have to rebuild the image, possibly with `--no-cache` to ensure you are installing the latest CLI. I have no idea. I guess you could curl stuff through the API.

### Usage Example

Values for your email and token can be found via the following commands:

```bash
heroku auth:whoami
heroku auth:token
```

You run the command task like so.

```bash
docker run \
  -e EMAIL="" \
  -e HEROKU_TOKEN="" \
  -e APP_NAME="" \
  -e PGHOST="" \
  -e PGUSER="" \
  -e PGPASSWORD="" \
  -e PGDATABASE="" \
  g5search/heroku-postgres-evacuator
```
