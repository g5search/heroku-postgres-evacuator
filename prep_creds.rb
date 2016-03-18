#!/usr/bin/ruby

def write_homedir(name, body)
  filename = ENV["HOME"]+"/" + name
  File.open(filename, "w") do |f|
    f.write(body)
  end
  system("chmod 0600 #{filename}")
end

write_homedir(
  ".netrc",
<<-EOF
machine api.heroku.com
  login #{ENV["EMAIL"]}
  password #{ENV["HEROKU_TOKEN"]}
machine git.heroku.com
  login #{ENV["EMAIL"]}
  password #{ENV["HEROKU_TOKEN"]}
EOF
)
