set :output, "log/cron.log"

every 1.minutes do
  rake "scrape:arrival_times"
end

every 1.minutes do
  rake "scrape:geocoded_vehicles"
end

every 1.week do
  rake "scrape:schedule_table"
end
