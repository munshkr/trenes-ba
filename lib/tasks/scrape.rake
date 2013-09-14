
namespace :scrape do
  desc "Scrape arrival times and dump to log files"
  task :arrival_times do
    require "lib/arrival_times_scraper"
    ArrivalTimesScraper.new.run
  end

  desc "Scrape schedule table and dump to file"
  task :schedule do
    require "lib/schedule_scraper"
    ScheduleScraper.new.run
  end

  desc "Scrape position of vehicles and dump to file"
  task :geocoded_vehicles do
    require "lib/geocoded_vehicles_scraper"
    GeocodedVehiclesScraper.new.run
  end
end
