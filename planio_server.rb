require 'net/http'
require 'json'


class PlanioServer

  def initialize planio_config
    @base_uri = "https://" + planio_config['domain']
    @apikey = planio_config['apikey'] 
    @threads = []
  end

  def request path, params = nil
    uri = URI(@base_uri + path)
    uri.query = URI.encode_www_form(params) unless params.nil?

    @threads << Thread.new(uri) do |uri|
      Thread.current[:name] = uri.path
      req = Net::HTTP::Get.new(uri.request_uri)
      req.basic_auth @apikey, 'nopass'

      res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') {|http|
        http.request(req)
      }
      yield res.body
      @threads.delete Thread.current
    end
  end

  def json_request path, params = nil
    self.request(path, params) do |response|
      resp = nil
      begin 
        resp = JSON.parse( response )
      rescue JSON::ParserError
      end
      yield resp
    end
  end

  def wait_for_current_threads
    Thread.new do
      @threads.each { |thread|  
        thread.join
      }
      yield
    end
  end

  def kill_current_threads
    @threads.delete_if { |thread|  
      Thread.kill thread
      true
    }
  end

  def get_projects
    self.json_request("/projects.json") do |response| 
      yield response['projects']
    end
  end

  def get_issues project_id, params
    self.json_request("/projects/#{project_id}/issues.json", params) do |response| 
      issues = []
      issues = response['issues'] unless response.nil? || response['issues'].nil?
      yield issues
    end
  end
  def start_project_timer project_id, started_at = nil
    # TODO
  end

  def start_issue_timer issue_id, started_at = nil
    # TODO
  end

  def stop_timer
    # TODO
  end

  def track_time
    # TODO
  end

  def threads
    @threads
  end
end


