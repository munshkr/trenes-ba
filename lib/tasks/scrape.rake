require "lib/schedule_scraper"
require "lib/arrival_times_scraper"

namespace :scrape do
  desc "Scrape arrival times and dump to log files"
  task :arrival_times do
    ArrivalTimesScraper.new.run
  end

  desc "Scrape schedule table and dump to file"
  task :schedule do
    ScheduleScraper.new.run
  end
end
