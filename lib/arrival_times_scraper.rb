require "lib/scraper"

class ArrivalTimesScraper < Scraper
  URL = "http://trenes.mininterior.gov.ar/ajax_arribos.php"
  HEADERS = {
    "Accept-Encoding" => "gzip,deflate,sdch",
    "Host" => "trenes.mininterior.gov.ar",
    "Referer" => "http://trenes.mininterior.gov.ar/index_mininterior_2.php",
    "User-Agent" => "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.22 (KHTML, like Gecko) Ubuntu Chromium/25.0.1364.160 Chrome/25.0.1364.160 Safari/537.22",
    "X-Requested-With" => "XMLHttpRequest",
  }
  KEY = "v%23v%23QTUtWp%23MpWRy80Q0knTE10I30kj%23JNyZ"
  CHARS = ('0'..'9').to_a + ('A'..'Z').to_a + ('a'..'z').to_a
  RETRIES = 10

  BRANCH_IDS = {
    sarmiento: 1,
    mitre_tigre: 5,
    mitre_mitre: 7,
    mitre_jlsuarez: 9,
  }


  def run
    times_per_branch.each do |branch, (time, data)|
      p = self.class.path(branch, Date.today)
      FileUtils.mkdir_p(File.dirname(p))
      File.open(p, 'a') do |f|
        f.puts [time.to_i, data].join(',')
      end
    end
  end

  def times_per_branch
    Enumerator.new do |yielder|
      BRANCH_IDS.each_key do |branch|
        yielder << [branch, download_times(branch)]
      end
    end
  end

  def self.path(branch, date)
    File.join(DATA_PATH, "times", branch.to_s, "#{date.strftime("%Y-%m")}.csv")
  end


private
  def random_string
    str = ''
    16.times { |i| str << CHARS[rand(CHARS.size)] }
    str
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
    data = nil
    time = nil

    cl = HTTPClient.new

    RETRIES.times do |i|
      res = cl.get(url(branch), HEADERS)
      sleep 0.3

      time = Time.parse(res.headers["Date"])
      data = res.body
      break if not data.size.zero?
      sleep 1
    end

    [time, data]
  end
end
