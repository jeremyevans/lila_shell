desc 'Setup the database'
task :bootstrap do
  sh 'createuser -U postgres lila_shell'
  sh 'createdb -U postgres -O lila_shell lila_shell'
  sh 'createdb -U postgres -O lila_shell lila_shell_test'
  sh 'sequel -E -m migrate postgres:///?user=lila_shell'
  sh 'sequel -E -m migrate postgres:///lila_shell_test?user=lila_shell'
end

desc 'Run model tests'
task :model_test do
  sh "#{FileUtils::RUBY} test/model_test.rb"
end

desc 'Run web tests'
task :web_test  do
  require 'securerandom'
  ENV['RACK_ENV'] = 'test'
  ENV['PORT'] ||= '3001'
  ENV['LILA_SHELL_DATABASE_URL'] ||= "postgres:///lila_shell_test?user=lila_shell"
  ENV['LILA_SHELL_SESSION_SECRET'] ||= SecureRandom.base64(48)

  sh "psql -U lila_shell -f test/clean.sql lila_shell_test"
  Process.spawn("#{ENV['UNICORN']||'unicorn'} -E test -p #{ENV['PORT']} -D -c test/unicorn.conf")
  begin
    sleep 1
    sh "#{FileUtils::RUBY} test/web_test.rb"
  ensure 
    Process.kill(:SIGTERM, File.read('test/unicorn.pid').to_i)
  end
end

default_specs = %w'model_test'
default_specs << 'web_test' if RUBY_VERSION > '2.5'
desc 'Run all specs'
task :default=>default_specs
