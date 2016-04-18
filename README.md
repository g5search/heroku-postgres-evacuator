## Heroku Postgres Evacuator

This is a containerized tool that can migrate a database out of heroku and to a non-heroku postgres database, repointing the heroku app. It uses S3 for final backup storage and can restore things back to heroku (including recreating the same database plan that was deleted). Some combination of environment variables also allow you to use this container as a database importer that doesn't disrupt the source app.

The destructive parts of this will only happen when you set `DESTRUCTIVE=true`. Otherwise it backs up and imports, but leaves Heroku untouched (aside from putting the app in maintenance mode during the process). You want to set the variable if you are moving an app's database but keeping the app on Heroku. If you are merely testing the destination, leave it off.

With `DESTRUCTIVE` set, this *can* be dangerous, because there is no way to alter the heroku `DATABASE_URL` while any database plan is still associated with the app. Yes, this means I have to delete the database plan. Scary. I will delete *every database plan*, even ones that are not the primary plan (again, required to change `DATABASE_URL`), but I will only capture a backup of the primary database. This means if you are doing something funky, like stashing a database for later, it might be eaten and never return.

With `CLEAN_TARGET=true`, you can tell the restore command to add the `--clean` flag. This will drop objects before creating them, which might be desirable when you've done a database migration once, tested it, and are about to go into production. You have to consider if some objects have been removed from the source since you last migrated, because those objects will remain on the target. In that case you might be better off recreating the target database to ensure it's clean (and then, ironically, you don't need this flag at all!).

Use `SKIP_SNAPSHOT=true` if you don't need to take a new snapshot in Heroku. It will skip that step and instead use the URL of the most recent backup.

Use `SKIP_MAINTENANCE=true` if you don't want to put the app into maintenance mode.

In my testing, even if you delete a database plan, the PGBackups in heroku remain. I have no idea why or how, but that does provide a minor amount of safety.

### Important Note on Usage

Unfortunately, the Heroku CLI that this depends upon has an auto-update facility that explodes quite frequently when the CLI baked into this image is out-of-date. Like, really frequently. As in this image becomes useless in a matter of days. Until they [address this issue](https://github.com/heroku/heroku-cli/issues/129), you're going to continue to have to rebuild the image, possibly with `--no-cache` to ensure you are installing the latest CLI. I have no idea. I guess you could curl stuff through the API.

### Usage Example

Values for your email and token can be found via the following commands:

```bash
heroku auth:whoami
heroku auth:token
```

You run the command task like so. Consider whether you want `DESTRUCTIVE=true` or not.

```bash
docker run \
  -e DESTRUCTIVE="true" \
  -e EMAIL="" \
  -e HEROKU_TOKEN="" \
  -e APP_NAME="" \
  -e PGHOST="" \
  -e PGUSER="" \
  -e PGPASSWORD="" \
  -e PGDATABASE="" \
  -e AWS_REGION="us-east-1" \
  -e AWS_S3_BUCKET="g5engineering" \
  -e AWS_S3_KEYBASE="dpetersen/rdsmove" \
  -e AWS_ACCESS_KEY_ID="" \
  -e AWS_SECRET_ACCESS_KEY="" \
  g5search/heroku-postgres-evacuator
```

For rollback, add `./rollback.sh` to the end of this command. The default is `import.sh`. It's possible that rollback won't do much if you didn't run with `DESTRUCTIVE=true`, I haven't checked. But that also doesn't seem like something you need to do.
