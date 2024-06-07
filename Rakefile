desc 'Setup the database'
task :bootstrap do
  sh 'createuser -U postgres lila_shell'
  sh 'createdb -U postgres -O lila_shell lila_shell'
  sh 'createdb -U postgres -O lila_shell lila_shell_test'
  sh 'sequel -E -m migrate postgres:///?user=lila_shell'
  sh 'sequel -E -m migrate postgres:///lila_shell_test?user=lila_shell'
end

test_flags = "-w" if RUBY_VERSION >= '3'

desc 'Run model tests'
task :model_test do
  sh "#{FileUtils::RUBY} #{test_flags} test/model_test.rb"
end

desc 'Run web tests'
task :web_test  do
  sh "#{FileUtils::RUBY} #{test_flags} test/web_test.rb"
end

default_specs = %w'model_test'
default_specs << 'web_test' if RUBY_VERSION > '3.0' && !ENV['NO_AJAX']
desc 'Run all specs'
task :default=>default_specs
