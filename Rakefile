
desc 'Setup the database'
task :bootstrap do
  sh 'createuser -U postgres lila_shell'
  sh 'createdb -U postgres -O lila_shell lila_shell'
  sh 'sequel -E -m migrate postgres:///?user=lila_shell'
end
