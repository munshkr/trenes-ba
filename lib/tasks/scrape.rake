namespace :scrape do
  DATA_PATH = File.expand_path("../../data", File.dirname(__FILE__))

  desc "Scrape arrival times and dump to log files"
  task :arrival_times do
    require "httpclient"
    require "csv"

    RETRIES = 3

    CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
    URL = "http://trenes.mininterior.gov.ar/ajax_arribos.php"
    KEY = "v%23v%23QTUtWp%23MpWRy80Q0knTE10I30kj%23JNyZ"

    HEADERS = {
      "Accept-Encoding" => "gzip,deflate,sdch",
      "Host" => "trenes.mininterior.gov.ar",
      "Referer" => "http://trenes.mininterior.gov.ar/index_mininterior_2.php",
      "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22",
      "X-Requested-With" => "XMLHttpRequest",
    }

    BRANCH_IDS = {
      sarmiento: 1,
      mitre_tigre: 5,
      mitre_mitre: 7,
      mitre_jlsuarez: 9,
    }

    def random_string
      str = ''
      16.times { |i| str << CHARS[rand(CHARS.size)] }
      return str
    end

    def url(branch)
      params = {
        ramal: BRANCH_IDS[branch],
        rnd: random_string,
        key: KEY,
      }
      "#{URL}?#{params.map { |k,v| "#{k}=#{v}" }.join('&')}"
    end

    def download_times(branch)
      times = nil
      cl = HTTPClient.new
      RETRIES.times do |i|
        res = cl.get(url(branch), HEADERS)
        times = res.body
        break if not times.size.zero?
        sleep 1
      end
      times
    end

    BRANCH_IDS.each_key do |branch|
      times = download_times(branch)
      File.open(File.join(DATA_PATH, "#{branch}.csv"), 'a') do |f|
        f.puts [Time.now.to_i, times].join(',')
      end
    end
  end

  desc "Scrape schedule table and dump to file"
  task :schedule_table do
    puts "=> TODO"
  end
end
