#!/usr/bin/ruby

[
  "EMAIL",
  "HEROKU_TOKEN",
  "APP_NAME",
  "PGHOST",
  "PGUSER",
  "PGPASSWORD",
  "PGDATABASE",
  "AWS_REGION",
  "AWS_S3_BUCKET",
  "AWS_SECRET_ACCESS_KEY",
  "AWS_ACCESS_KEY_ID"
].each do |s|
  if ENV[s] == ""
    puts "#{s} must be provided as an environment variable!"
    exit 1
  end
end
