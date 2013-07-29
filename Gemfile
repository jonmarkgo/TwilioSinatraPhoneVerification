source 'https://rubygems.org'
gem "sinatra"
gem "sinatra-contrib"
gem "data_mapper"
gem "twilio-ruby"
gem "sanitize"

group :production do
    gem "pg"
    gem "dm-postgres-adapter"
end

group :development, :test do
    gem "sqlite3"
    gem "dm-sqlite-adapter"
end

