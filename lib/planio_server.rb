require 'net/http'
require 'json'


class PlanioServer

  def initialize planio_tracker
    planio_config = planio_tracker.get_config
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
      threads = Array.new @threads
      threads.each { |thread|  
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

  def track_time trackings
    success = true
    threads = []
    trackings.each do |tracking|
      uri = URI(@base_uri + '/time_entries.json')
      params = Hash.new
      if tracking[:issue].nil? || tracking[:issue]['id'].nil?
        params['time_entry[project_id]'] = tracking[:project]['id']
      else
        params['time_entry[issue_id]'] = tracking[:issue]['id']
      end
      # TODO find out day of time tracking
      #params['spent_on'] = tracking[:project]['stopped_at']...
      params['time_entry[hours]'] = (tracking[:stopped_at] - tracking[:started_at]) / 3600
      #params['comments'] = ""
      #params['activity_id'] = ...
      uri.query = URI.encode_www_form(params) unless params.nil?
      puts(uri.request_uri)
      threads << Thread.new(uri) do |uri|
        Thread.current[:name] = uri.path
        req = Net::HTTP::Post.new(uri.request_uri)
        req.basic_auth @apikey, 'nopass'

        res = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') {|http|
          response = http.request(req)
          success = false if response.message != 'Created'
        }
      end
    end
    threads.each { |aThread|  aThread.join }
    yield success
  end

  def threads
    @threads
  end
end


