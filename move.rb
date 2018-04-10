#!/usr/bin/ruby

require 'aws-sdk'
require './shared'

pg_aas = get_pg_addons()
prod_aa = find_prod(pg_aas)

plan = prod_aa["plan"]["name"].strip
if plan == ""
  puts "couldn't determine plan name"
  exit 1
end

if ENV["AWS_S3_BUCKET"] == ""
  puts "must supply AWS_S3_BUCKET"
  exit 1
end

bucket = Aws::S3::Resource.new().bucket(ENV["AWS_S3_BUCKET"])
plan_obj = bucket.object(ENV["AWS_S3_KEYBASE"] + "/" + ENV["APP_NAME"] + ".plan")
plan_obj.put(body: plan)
puts "determined and backed up plan type: #{plan}"

run("turning on maintenance", app_suffix("heroku maintenance:on"))

run("capturing", app_suffix("heroku pg:backups capture DATABASE_URL"))

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

# the --jobs is a totally made-up number, but in the context I'm running this
# thing, that number is almost always reasonable. I hope.
run("restoring", "pg_restore --jobs=2 -d #{ENV["PGDATABASE"]} #{clean_flag} --verbose --no-acl --no-owner -e --schema=public #{local}", false)

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

run("turning off maintenance", app_suffix("heroku maintenance:off"))
