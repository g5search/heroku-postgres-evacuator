require 'json'
require 'open3'

def run(pre, cmd, showout=true, env={})
  puts(pre + "...")
  puts cmd

  out = ""
  Open3.popen3(env, cmd) do |_, stdout, stderr, wait_thr|
    status = wait_thr.value

    out = stdout.read.chomp
    puts "STDOUT:\n #{out}"
    puts "STDERR:\n #{stderr.read.chomp}"

    if status.exitstatus != 0
      puts "non-zero exist code for '#{cmd}': #{status.inspect}"
      puts "MAINTENANCE MODE MAY STILL BE ON!"
      exit 1
    end
  end

  out
end

def app_suffix(s)
  s + " --app=#{ENV["APP_NAME"]}"
end


def get_pg_addons()
  addons = JSON.parse(`#{app_suffix("heroku addons --json")}`)
  pg_aas = addons.select { |aa| aa["addon_service"]["name"] == "heroku-postgresql" }

  return pg_aas
end

def find_prod(pg_aas)
  prod_aa = pg_aas.select { |aa| aa["config_vars"].include?("DATABASE_URL") }
  if prod_aa.length != 1
    puts "couldn't determine a single production database plan: #{prod_aa.length}"
    exit 1
  end

  return prod_aa[0]
end

def pg_restore(clean_flag, local)
  # the --jobs is a totally made-up number, but in the context I'm running this
  # thing, that number is almost always reasonable. I hope.
  run(
    "restoring",
    "pg_restore --jobs=2 -d #{ENV["DATABASE_NAME"]} --host=#{ENV["DATABASE_HOST"]} --username=#{ENV["DATABASE_USER"]} --port=#{ENV["DATABASE_PORT"]} #{clean_flag} --verbose --no-acl --no-owner -e --schema=public #{local}",
    false,
    # not passing this as a flag because then it would show up in the logs.
    # It's a "magic" postgres var that will automatically be used by any
    # postgres CLI command
    { "PGPASSWORD" => ENV["DATABASE_PASSWORD"] }
  )
end
