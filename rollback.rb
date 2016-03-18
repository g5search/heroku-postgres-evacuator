#!/usr/bin/ruby

require 'aws-sdk'
require './shared'

run("turning on maintenance", app_suffix("heroku maintenance:on"))

bucket = Aws::S3::Resource.new().bucket(ENV["AWS_S3_BUCKET"])
plan_obj = bucket.object(ENV["AWS_S3_KEYBASE"] + "/" + ENV["APP_NAME"] + ".plan")
plan = plan_obj.get.body.read
puts "found plan: #{plan}"

db_key = ENV["AWS_S3_KEYBASE"] + "/" + ENV["APP_NAME"] + ".dump"
db_url = Aws::S3::Presigner.new.presigned_url(
  :get_object,
  bucket: ENV["AWS_S3_BUCKET"],
  key: db_key
)

run("removing DATABASE_URL", app_suffix("heroku config:remove DATABASE_URL"))
run("creating db addon: #{plan}", app_suffix("heroku addons:create #{plan}"))
run("running pg:backups restore", app_suffix("heroku pg:backups restore '#{db_url}' DATABASE_URL --confirm #{ENV["APP_NAME"]}"))
run("turning off maintenance", app_suffix("heroku maintenance:off"))
