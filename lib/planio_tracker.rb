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
    # copy the list just in case it gets modified during the server upload
    Array.new(@trackings.reject{|tracking| tracking == @current})
  end

  def start project, issue = nil, started_at = DateTime.now
    stop unless @current.nil?
    @current = {:project => project, :started_at => started_at}
    @current[:issue] = issue unless issue.nil?
    @trackings << @current
    write_times
  end

  def stop
    @current[:stopped_at] = DateTime.now unless @current.nil?
    @current = nil
    write_times
  end

  def remove trackings
    trackings.each do
      @trackings.remove trackings
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
      times = read '.planio/times'
      times.is_a?(Array) ? times : []
    rescue
      []
    end
  end

  def write_times
    write('.planio/times') do |out|
      YAML.dump @trackings, out
    end
  end

  def read path
    YAML::load(File.read(home_path(path)))
  end

  def write path
    File.open(home_path(path), 'w') do |out|
      yield out
    end
  end

  def home_path path
    File.join(ENV['HOME'], path)
  end
end
