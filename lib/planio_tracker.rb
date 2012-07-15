require 'yaml'

class PlanioTracker
  def initialize
    @projects = read_all
    @current = find_current
  end

  def get_current
    @current
  end

  def get_stopped
    @current
  end

  def start_project project_id, started_at = DateTime.now
    stop unless @current.nil?
    @current = {:project => project_id, :started_at => started_at}
    @projects << @current
    write_all
  end

  def start_issue project_id, issue_id, started_at = DateTime.now
    stop unless @current.nil?
    @current = {:project => project_id, :issue => issue_id, :started_at => started_at}
    @projects << @current
    write_all
  end

  def stop
    @current[:stopped_at] = DateTime.now
  end

  def track_time server
    # copy the list just in case it gets modified during the server upload
    projects = @projects.map
    server.track_time projects do |successful|
      if successful
        projects.each do
          @projects.remove projects
        end
      end
    end
  end

  protected

  def find_current
    puts @projects
    currents = @projects.select do |project|
      project[:stopped_at].nil?
    end
    throw MultiTrackingError if currents.size > 1
    return currents.first
  end

  def read_all
    begin
      YAML::load(File.read(File.join(ENV['HOME'], '.planio/times')))
    rescue
      []
    end
  end

  def write_all
    File.open(File.join(ENV['HOME'], '.planio/times'), 'w') do |out|
      YAML.dump @projects, out
    end
  end

end
