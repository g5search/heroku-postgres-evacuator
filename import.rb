#!/usr/bin/ruby

require 'aws-sdk'
require './shared'

skip_maintenance = (ENV["SKIP_MAINTENANCE"] == "true")

pg_aas = get_pg_addons()
prod_aa = find_prod(pg_aas)

plan = prod_aa["plan"]["name"].strip
if plan == ""
  puts "couldn't determine plan name"
  exit 1
end

bucket = Aws::S3::Resource.new().bucket(ENV["AWS_S3_BUCKET"])
plan_obj = bucket.object(ENV["AWS_S3_KEYBASE"] + "/" + ENV["APP_NAME"] + ".plan")
plan_obj.put(body: plan)
puts "determined and backed up plan type: #{plan}"

unless skip_maintenance
  run("turning on maintenance", app_suffix("heroku maintenance:on"))
end

if ENV["SKIP_SNAPSHOT"] == "true"
  puts "skipping snapshot..."
else
  run("capturing", app_suffix("heroku pg:backups capture DATABASE_URL"))
end

remote = run("fetching URL", app_suffix("heroku pg:backups public-url"), false)
local = "/#{ENV["APP_NAME"]}.dump"
run("downloading", "curl -o #{local} \"#{remote}\"")

dump_obj = bucket.object(ENV["AWS_S3_KEYBASE"] + "/" + ENV["APP_NAME"] + ".dump")
dump_obj.upload_file(local)

clean_flag = ""
if ENV["CLEAN_TARGET"] == "true"
  puts "adding --clean!"
  clean_flag = "--clean"
end

run("restoring", "pg_restore -d #{ENV["PGDATABASE"]} #{clean_flag} --verbose --no-acl --no-owner -e --schema=public #{local}", false)

if ENV["DESTRUCTIVE"] == "true"
  pg_aas.each do |aa|
    name = aa["name"]
    run("removing db addon: #{name}", app_suffix("heroku addons:destroy #{name} --confirm #{ENV["APP_NAME"]}"))
  end

  url = [
    "postgres://",
    ENV["PGUSER"], ":", ENV["PGPASSWORD"],
    "@",
    ENV["PGHOST"], ":", ENV["PGPORT"],
    "/",
    ENV["PGDATABASE"]
  ].join("")
  run("resetting DATABASE_URL=#{url}", app_suffix("heroku config:set DATABASE_URL=#{url}"))
else
  puts "skipping destructive actions"
end

unless skip_maintenance
  run("turning off maintenance", app_suffix("heroku maintenance:off"))
end
