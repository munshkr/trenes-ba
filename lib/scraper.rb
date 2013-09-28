require "httpclient"
require "bzip2"

class Scraper
  DATA_PATH = File.join(APP_ROOT, "data")

  def run
    raise NotImplementedError
  end
end
