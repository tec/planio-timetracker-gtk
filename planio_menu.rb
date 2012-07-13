require "ruby-libappindicator"

class PlanioMenuIssue
  #FILTER_PARAMS_MY_OPEN = {"set_filter" => "1", "f[]" => "status_id", "op[status_id]" => "o", "v[status_id][]" => "1", "f[]" => "assigned_to_id", "op[assigned_to_id]" => "=", "v[assigned_to_id][]" => "me"}
  #FILTER_PARAMS_MY_OPEN = {"set_filter" => "1", "f[]" => "status_id", "op[status_id]" => "o", "v[status_id][]" => "1", "f[]" => "assigned_to_id", "op[assigned_to_id]" => "=", "v[assigned_to_id][]" => "me"}
  FILTER_PARAMS_MY_OPEN = "?set_filter=1&f[]=status_id&op[status_id]=o&v[status_id][]=1&f[]=assigned_to_id&op[assigned_to_id]=%3D&v[assigned_to_id][]=me&c[]=subject"
  def initialize issue
    @id = issue['id']
    @subject = issue['subject']

    @menu_item = Gtk::MenuItem.new @subject
    @menu_item.signal_connect "activate" do |my_menu_item|
      puts @id.to_s + ": " + @subject.to_s
    end
  end
  def menu_item
    @menu_item
  end
end

class PlanioMenuProject
  def initialize project, issues
    @identifier = project['identifier']
    @id         = project['id']
    @name       = project['name']
    create_menu issues
  end

  def menu_item
    @menu_item
  end

  protected

  def create_menu issues
    @menu_item = Gtk::MenuItem.new @name
    if issues.empty?
      @menu_item.signal_connect "activate" do |my_menu_item|
        # TODO
        puts "starting #{@id}"
      end
    else
      @menu_item.submenu = Gtk::Menu.new
      add_track_time_button
      issues.each do |issue|
        @menu_item.submenu.append PlanioMenuIssue.new( issue ).menu_item
      end
    end
  end

  def add_track_time_button
      button = Gtk::MenuItem.new "start time tracking on project"
      button.signal_connect "activate" do |my_menu_item|
        # TODO
        puts "starting #{@id}"
      end
      @menu_item.submenu.append button
      @menu_item.submenu.append Gtk::SeparatorMenuItem.new
  end
end

class PlanioMenu

  def initialize server
    @server = server
    @menu = Gtk::Menu.new
    
    @ai = AppIndicator::AppIndicator.new("planio-tracker", "indicator-messages", AppIndicator::Category::APPLICATION_STATUS)
    @ai.set_menu @menu
    @ai.set_status AppIndicator::Status::ACTIVE

    refresh
  end

  def start
    Gtk.main
  end

protected

  def refresh
    @menu.children.each do |item|
      @menu.remove item
    end
    add_refresh_button
    add_stop_time_button
    @menu.append Gtk::SeparatorMenuItem.new
    @menu.show_all
    self.load_projects
  end

  def load_projects
    @server.get_projects do |projects| 
      projects.each do |project|
        @server.get_issues( project['id'], PlanioMenuIssue::FILTER_PARAMS_MY_OPEN ) do |issues|
          @menu.append PlanioMenuProject.new( project, issues ).menu_item
          @menu.show_all
        end
      end
      @server.wait_for_current_threads do
        puts "projects refreshed"
        #puts @server.threads.inspect
      end
    end
  end

  def add_refresh_button
      button = Gtk::MenuItem.new "Refresh projects and issues"
      button.signal_connect "activate" do |my_menu_item|
        @server.kill_current_threads
        self.refresh
      end
      @menu.append button
  end

  def add_stop_time_button
      button = Gtk::MenuItem.new "Stop time tracking"
      button.signal_connect "activate" do |my_menu_item|
        # TODO
        puts "stopping"
      end
      @menu.append button
  end
end

