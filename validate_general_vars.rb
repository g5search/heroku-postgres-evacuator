#!/usr/bin/ruby

[
  "EMAIL",
  "HEROKU_TOKEN",
  "APP_NAME",
  "DATABASE_HOST",
  "DATABASE_USER",
  "DATABASE_PASSWORD",
  "DATABASE_DATABASE",
].each do |s|
  if ENV[s] == ""
    puts "#{s} must be provided as an environment variable!"
    exit 1
  end
end
