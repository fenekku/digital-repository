set :output, '/home/deploy/cron.log'

job_type :rake, "{ cd :path > /dev/null; } && RAILS_ENV=:environment bundle exec rake :task --silent :output"
job_type :runner, "{ cd :path > /dev/null; } && RAILS_ENV=:environment bundle exec rails runner ':task' :output"

every 1.week, at: '1:00 am' do
  rake 'sufia:stats:user_stats'
end
