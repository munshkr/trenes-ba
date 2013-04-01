set :output, "log/cron.log"

every 2.minutes do
  rake "scrape:arrival_times"
end

every 1.day do
  rake "scrape:schedule_table"
end
