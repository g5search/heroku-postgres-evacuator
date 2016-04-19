#!/usr/bin/ruby

[
  "EMAIL",
  "HEROKU_TOKEN",
  "APP_NAME",
  "PGHOST",
  "PGUSER",
  "PGPASSWORD",
  "PGDATABASE",
].each do |s|
  if ENV[s] == ""
    puts "#{s} must be provided as an environment variable!"
    exit 1
  end
end
