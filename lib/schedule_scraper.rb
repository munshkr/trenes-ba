require "lib/scraper"
require "nokogiri"

class ScheduleScraper < Scraper
  URL = "http://www.mitresarmiento.com.ar/horarios.asp"
  RETRIES = 10

  DAYS_IDS = {
    monday_to_friday: 2,
    working_saturdays: 7,
    sundays_and_holidays: 1,
  }

  ROUTE_PER_BRANCH = {
    sarmiento:      %w{ O CB F FT VL LS CD RM HD M CL Y PA RO PR MO },
    mitre_tigre:    %w{ RN LT BC NZ RV VZ OL LL N AS SW BE Z VY FB CU T },
    mitre_mitre:    %w{ RN TF MZ AL NR CI DR BJ FD CG BM },
    mitre_jlsuarez: %w{ RN TF MZ AL NR DD UZ PY MG SM SA MA BL CH JL },
  }

  HOUR_RE = /^\d{2}:\d{2}$/


  def run
    DAYS_IDS.each_key do |days|
      ROUTE_PER_BRANCH.each do |branch, route|
        [:departure, :return].each do |way|
          p = self.class.path(branch, Date.today, days, way)
          FileUtils.mkdir_p(File.dirname(p))

          File.open(p, 'w') do |f|
            route = route.reverse if way == :return

            only_save_b = false
            route.each_slice(2) do |a, b|
              only_save_b = true if b.nil?

              if only_save_b
                # This is the odd-numbered terminal station, so make a request
                # for the previous station and this one.
                b = a
                a = route[-2]
              end

              a_to_b = case way
                when :departure then download_table(a, b, days)
                when :return    then download_table(b, a, days)
                else raise "Unknown way"
              end

              ta, tb = a_to_b.transpose

              f.puts ta.join(",") if not only_save_b
              f.puts tb.join(",")
            end
          end
        end
      end
    end
  end

  def self.path(branch, date, days, way)
    File.join(DATA_PATH, "schedule", branch.to_s, "#{date.strftime("%Y-%m")}-#{way}-#{days}.csv")
  end


private
  def download_table(origin, destination, days)
    table = nil
    params = {
      "EstOri" => origin,
      "EstDes" => destination,
      "Hsale"  => "00:00",
      "Hllega" => "24:00",
      "Dias"   => DAYS_IDS[days],
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

  def parse_table(doc)
    doc.css("table tr td")
       .map { |td| td.text.strip }
       .select { |text| text =~ HOUR_RE }
       .each_slice(2)
       .to_a
  end
end
