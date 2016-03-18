require 'json'

def run(pre, cmd, showout=true)
  puts(pre + "...")
  puts cmd
  s = `#{cmd}`
  puts s if showout
  if $?.exitstatus != 0
    puts "non-zero exist code for '#{cmd}': #{$?.inspect}"
    puts "MAINTENANCE MODE MAY STILL BE ON!"
    exit 1
  end

  s.strip
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
