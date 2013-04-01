require "httpclient"

namespace :scrape do
  DATA_PATH = File.expand_path("../../data", File.dirname(__FILE__))

  RETRIES = 3
  HEADERS = {
    "Accept-Encoding" => "gzip,deflate,sdch",
    "Host" => "trenes.mininterior.gov.ar",
    "Referer" => "http://trenes.mininterior.gov.ar/index_mininterior_2.php",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22",
    "X-Requested-With" => "XMLHttpRequest",
  }


  desc "Scrape arrival times and dump to log files"
  task :arrival_times do
    CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
    URL = "http://trenes.mininterior.gov.ar/ajax_arribos.php"
    KEY = "v%23v%23QTUtWp%23MpWRy80Q0knTE10I30kj%23JNyZ"

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
        sleep 0.3
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
    require "nokogiri"

    URL = "http://www.mitresarmiento.com.ar/horarios.asp"

    DAYS_IDS = {
      monday_to_friday: 2,
      working_saturdays: 7,
      sundays_and_holidays: 1,
    }

    HOUR_RE = /^\d{2}:\d{2}$/

    ROUTE_PER_BRANCH = {
      sarmiento:      %w{ },    # TODO
      mitre_tigre:    %w{ RN LT BC NZ RV VZ OL LL N AS SW BE Z VY FB CU T },
      mitre_mitre:    %w{ RN TF MZ AL NR CI DR BJ FD CG BM },
      mitre_jlsuarez: %w{ RN TF MZ AL NR DD UZ PY MG SM SA MA BL CH JL },
    }


    def parse_table(doc)
      doc.css("table tr td")
         .map { |td| td.text.strip }
         .select { |text| text =~ HOUR_RE }
         .each_slice(2)
         .to_a
    end

    def download_table(origin, destination, days)
      table = nil
      params = {
        "EstOri" => origin,
        "EstDes" => destination,
        "Hsale" => "00:00",
        "Hllega" => "24:00",
        "Dias" => DAYS_IDS[days],
      }

      html = nil
      cl = HTTPClient.new
      RETRIES.times do |i|
        res = cl.post(URL, params)
        html = res.body
        break if not html.size.zero?
        sleep 1
      end

      doc = Nokogiri::HTML(html)
      parse_table(doc)
    end


    DAYS_IDS.each_key do |days|
      ROUTE_PER_BRANCH.each do |branch, route|
        File.open(File.join(DATA_PATH, "sched__#{branch}__#{days}.csv"), 'a') do |f|
          route.each_slice(2) do |a, b|
            table = download_table(a, b, days)
            f.puts [Date.today.to_s, table.inspect].join(',')
          end
        end
      end
    end

  end
end
