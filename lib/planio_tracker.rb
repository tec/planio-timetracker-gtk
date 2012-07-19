require 'yaml'

class PlanioTracker
  def initialize
    @config = read_config
    @trackings = read_times
    @current = find_current
  end

  def get_config
    @config
  end

  def get_current
    @current
  end

  def get_stopped
    # TODO test
    @trackings.reject{|tracking| tracking == @current}
  end

  def start_project project_id, started_at = DateTime.now
    stop unless @current.nil?
    @current = {:project => project_id, :started_at => started_at}
    @trackings << @current
    write_times
  end

  def start_issue project_id, issue_id, started_at = DateTime.now
    stop unless @current.nil?
    @current = {:project => project_id, :issue => issue_id, :started_at => started_at}
    @trackings << @current
    write_times
  end

  def stop
    @current[:stopped_at] = DateTime.now
    @current = nil
  end

  def track_time server
    # copy the list just in case it gets modified during the server upload
    trackings = @trackings.map
    server.track_time trackings do |successful|
      if successful
        trackings.each do
          @trackings.remove trackings
        end
      end
    end
  end

  protected

  def find_current
    currents = @trackings.select do |project|
      project[:stopped_at].nil?
    end
    throw MultiTrackingError if currents.size > 1
    return currents.first
  end

  def read_config
    read '.planio/config'
  end

  def read_times
    begin
      read '.planio/times'
    rescue
      []
    end
  end

  def write_times
    write('.planio/times') do |out|
      YAML.dump @trackings, out
    end
  end

  def read home_path
    YAML::load(File.read(File.join(ENV['HOME'], home_path)))
  end

  def write home_path
    File.open(File.join(ENV['HOME'], home_path), 'w') do |out|
      yield
    end
  end
end
