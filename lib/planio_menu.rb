require "ruby-libappindicator"
require './lib/planio_notifier.rb'

class PlanioMenuIssue
  FILTER_PARAMS        = [["set_filter", "1"]]
  FILTER_PARAMS_OPEN   = [["f[]", "status_id"], ["op[status_id]", "o"], ["v[status_id][]", "1"]]
  FILTER_PARAMS_MY     = [["f[]", "assigned_to_id"], ["op[assigned_to_id]", "="], ["v[assigned_to_id][]", "me"]]

  def initialize tracker, project, issue
    @tracker = tracker
    @project = project
    @issue = issue
    @id = issue['id']
    @subject = issue['subject']

    @menu_item = Gtk::MenuItem.new @subject
    @menu_item.signal_connect "activate" do |my_menu_item|
      track_time
    end
  end

  def menu_item
    @menu_item
  end

  def track_time
    @tracker.start @project, @issue
    PlanioNotifier.show "Time tracking started on \nproject '#{@project['name']}' \nissue '#{@subject}'", "tracking #{@project['id']}##{@id}"
  end

  def self.get_filter
    FILTER_PARAMS + FILTER_PARAMS_OPEN + FILTER_PARAMS_MY
  end
end

class PlanioMenuProject
  def initialize tracker, project, issues
    @tracker    = tracker
    @project    = project
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
        @menu_item.submenu.append PlanioMenuIssue.new( @tracker, project, issue ).menu_item
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
    @tracker.start @project
    PlanioNotifier.show "Time tracking started on project \n'#{@name}'", "tracking #{@id}"
  end
end

class PlanioMenu

  def initialize tracker, server
    @tracker = tracker
    @server = server
    @menu = Gtk::Menu.new
    @projects = []
    @mutex = Mutex.new
    
    @ai = AppIndicator::AppIndicator.new("planio-tracker", "planio", AppIndicator::Category::APPLICATION_STATUS, File.absolute_path("media/22"))
    @ai.set_menu @menu
    @ai.set_status AppIndicator::Status::ACTIVE

    add_refresh_button
    add_stop_time_button
    add_upload_trackings_button
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
    @mutex.synchronize do
      @projects.each do |item|
        @menu.remove item
      end
      @projects.clear
    end
    self.load_projects &block
  end

  def load_projects &block
    first_project_position = @menu.children.size
    @server.get_projects do |projects|
      projects.each do |project|
        @server.get_issues( project['id'], PlanioMenuIssue::get_filter ) do |issues|
          @mutex.synchronize do
            project_item = PlanioMenuProject.new( @tracker, project, issues ).menu_item
            added = false
            @menu.children.each_with_index do |item, i|
              if i >= first_project_position && item.label.casecmp(project_item.label) > 0
                @menu.insert project_item, i
                added = true
                break
              end
            end # menu.children
            @menu.append project_item unless added
            @projects.push project_item
            @menu.show_all
          end # mutex
        end # get_issues
      end # projects.each
      @server.wait_for_current_threads &block
    end # get_projects
  end

  def add_refresh_button
    # TODO fix label
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
      @tracker.stop
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

  def add_upload_trackings_button
    button = Gtk::MenuItem.new "Upload trackings"
    button.signal_connect "activate" do |my_menu_item|
      trackings = show_comments_dialog
      @server.track_time trackings do |successful|
        if successful
          # TODO test the code for successful == true
          @tracker.remove trackings
          trackings_text = trackings.map do |tracking|
            time = tracking[:started_at] - tracking[:stopped_at]
            minutes = time / 60
            hours = minutes / 60
            minutes = minutes % 60
            (tracking[:issue_name].nil? ? tracking[:project_name] : trackings[:issue_name]) + 
              ": #{hours}:#{minutes}h"
          end.join("\n")
          PlanioNotifier.show trackings_text, "Time tracking uploaded"
        else
          PlanioNotifier.show "Time tracking upload error"
        end
      end
    end
    @menu.append button
  end

  def show_comments_dialog
    trackings = @tracker.get_stopped
    # TODO show dialog that allows for adding comments
    trackings
  end
end

