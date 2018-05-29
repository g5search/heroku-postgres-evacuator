FROM debian:jessie
MAINTAINER G5 Engineering <engineering@getg5.com>

RUN apt-get update
RUN apt-get install -y wget curl ruby

# Heroku now requires a newer version of pg_restore that is only available via
# the postgres apt repo
RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main" > /etc/apt/sources.list.d/pgdg.list &&\
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - &&\
    apt-get update &&\
    apt-get install -y postgresql-client

RUN echo "deb http://toolbelt.heroku.com/ubuntu ./" > /etc/apt/sources.list.d/heroku.list &&\
    wget -O- https://toolbelt.heroku.com/apt/release.key | apt-key add - &&\
    apt-get update &&\
    apt-get install -y heroku-toolbelt

# Installs a bunch of the plugins that apparently aren't in the base
RUN heroku version

# Email can be discovered with `heroku auth:whoami`, token with `heroku auth:token`
ENV EMAIL="" \
    HEROKU_TOKEN="" \
    APP_NAME="" \
    PGHOST="" \
    PGPORT="5432" \
    PGUSER="" \
    PGPASSWORD="" \
    PGDATABASE="" \
    AWS_REGION="" \
    AWS_S3_BUCKET="" \
    AWS_S3_KEYBASE="" \
    AWS_ACCESS_KEY_ID="" \
    AWS_SECRET_ACCESS_KEY=""

RUN gem install --no-document bundler
COPY Gemfile Gemfile.lock /
RUN bundle install

COPY *.rb /
RUN chmod a+x validate_general_vars.rb validate_aws_vars.rb prep_creds.rb import.rb move.rb rollback.rb

COPY *.sh /
RUN chmod a+x import.sh move.sh rollback.sh

CMD /import.sh
