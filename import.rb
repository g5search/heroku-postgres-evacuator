#!/usr/bin/ruby

require 'aws-sdk'
require './shared'

if ENV["SKIP_SNAPSHOT"] == "true"
  puts "skipping snapshot..."
else
  run("capturing", app_suffix("heroku pg:backups capture DATABASE_URL"))
end

remote = run("fetching URL", app_suffix("heroku pg:backups public-url"), false)
local = "/#{ENV["APP_NAME"]}.dump"
run("downloading", "curl -o #{local} \"#{remote}\"")

clean_flag = ""
if ENV["CLEAN_TARGET"] == "true"
  puts "adding --clean!"
  clean_flag = "--clean"
end

# the --jobs is a totally made-up number, but in the context I'm running this
# thing, that number is almost always reasonable. I hope.
run("restoring", "pg_restore --jobs=2 -d #{ENV["PGDATABASE"]} #{clean_flag} --verbose --no-acl --no-owner -e --schema=public #{local}", false)
