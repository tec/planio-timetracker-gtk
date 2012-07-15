require "ruby-libappindicator"
require './lib/planio_notifier.rb'

class PlanioMenuIssue
  FILTER_PARAMS        = [["set_filter", "1"]]
  FILTER_PARAMS_OPEN   = [["f[]", "status_id"], ["op[status_id]", "o"], ["v[status_id][]", "1"]]
  FILTER_PARAMS_MY     = [["f[]", "assigned_to_id"], ["op[assigned_to_id]", "="], ["v[assigned_to_id][]", "me"]]

  def initialize project, issue
    @id = issue['id']
    @subject = issue['subject']
    @project = project

    @menu_item = Gtk::MenuItem.new @subject
    @menu_item.signal_connect "activate" do |my_menu_item|
      track_time
    end
  end

  def menu_item
    @menu_item
  end

  def track_time
    # TODO
    PlanioNotifier.show "Time tracking started on \nproject '#{@project['name']}' \nissue '#{@subject}'", "tracking #{@project['id']}##{@id}"
  end

  def self.get_filter
    FILTER_PARAMS + FILTER_PARAMS_OPEN + FILTER_PARAMS_MY
  end
end

class PlanioMenuProject
  def initialize project, issues
    @identifier = project['identifier']
    @id         = project['id']
    @name       = project['name']
    create_menu project, issues
  end

  def menu_item
    @menu_item
  end

  protected

  def create_menu project, issues
    @menu_item = Gtk::MenuItem.new @name
    if issues.empty?
      @menu_item.signal_connect "activate" do |my_menu_item|
        track_time
      end
    else
      @menu_item.submenu = Gtk::Menu.new
      add_track_time_button
      issues.each do |issue|
        @menu_item.submenu.append PlanioMenuIssue.new( project, issue ).menu_item
      end
    end
  end

  def add_track_time_button
      button = Gtk::MenuItem.new "start time tracking on project"
      button.signal_connect "activate" do |my_menu_item|
        track_time
      end
      @menu_item.submenu.append button
      @menu_item.submenu.append Gtk::SeparatorMenuItem.new
  end

  def track_time
        # TODO
        PlanioNotifier.show "Time tracking started on project \n'#{@name}'", "tracking #{@id}"
  end
end

class PlanioMenu

  def initialize server
    @server = server
    @menu = Gtk::Menu.new
    @projects = []
    
    @ai = AppIndicator::AppIndicator.new("planio-tracker", "indicator-messages", AppIndicator::Category::APPLICATION_STATUS)
    @ai.set_menu @menu
    @ai.set_status AppIndicator::Status::ACTIVE

    add_refresh_button
    add_stop_time_button
    add_close_button
    @menu.append Gtk::SeparatorMenuItem.new
    @menu.show_all

    refresh do 
      PlanioNotifier.show "Projects and issues successfully loaded", "refreshed"
    end
  end

  def start
    Gtk.main
  end

protected

  def refresh &block
    @projects.each do |item|
      @menu.remove item
    end
    @projects.clear
    self.load_projects &block
  end

  def load_projects &block
    @server.get_projects do |projects| 
      projects.each do |project|
        @server.get_issues( project['id'], PlanioMenuIssue::get_filter ) do |issues|
          project_item = PlanioMenuProject.new( project, issues ).menu_item
          @projects.push project_item
          @menu.append project_item
          @menu.reorder_child project_item, 0
          @menu.show_all
        end
      end
      @server.wait_for_current_threads &block
    end
  end

  def add_refresh_button
      refreshing = 0 # Count if user clicked multiple times on the button; 
      default_label = "Refresh projects and issues"
      refreshing_label = "-- Refreshing projects and issues --"
      button = Gtk::MenuItem.new default_label
      button.signal_connect "activate" do |my_menu_item|
        refreshing += 1
        button.label = refreshing_label
        @server.kill_current_threads
        self.refresh do
          refreshing -= 1
          # only set the label if all callbacks returned
          button.label = default_label if refreshing == 0
          PlanioNotifier.show "Projects and issues successfully loaded", "refreshed"
        end
      end
      @menu.append button
  end

  def add_stop_time_button
      button = Gtk::MenuItem.new "Stop time tracking"
      button.signal_connect "activate" do |my_menu_item|
        # TODO
        PlanioNotifier.show "Time tracking stopped"
      end
      @menu.append button
  end

  def add_close_button
      button = Gtk::MenuItem.new "Close"
      button.signal_connect "activate" do |my_menu_item|
        PlanioNotifier.show "", "closed"
        Gtk.main_quit
      end
      @menu.append button
  end
end

