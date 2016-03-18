## Heroku Postgres Evacuator

This is a containerized tool that can migrate a database out of heroku and to a non-heroku postgres database, repointing the heroku app. It uses S3 for final backup storage and can restore things back to heroku (including recreating the same database plan that was deleted).

This *can* be dangerous. There is no way to alter the heroku DATABASE_URL while any database plan is still associated with the app. Yes, this means I have to delete the database plan. Scary. I will delete *every database plan*, even ones that are not the primary plan (again, required to change DATABASE_URL), but I will only capture a backup of the primary database. This means if you are doing something funky, like stashing a database for later, it might be eaten and never return.

In my testing, even if you delete a database plan, the PGBackups in heroku remain. I have no idea why or how, but that does provide a minor amount of safety.

### Usage Example

Values for your email and token can be found via the following commands:

```bash
heroku auth:whoami
heroku auth:token
```

```bash
docker run \
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

For rollback, add `./rollback.sh` to the end of this command. The default is `import.sh`.
