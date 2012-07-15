begin
  require 'rubygems'
  require 'libnotify'
  class PlanioNotifier
	@@libnotify = Libnotify.new
    def self.show message, title = ""
      @@libnotify.update(:summary => "Planio: " + title, :body => message, :append => false)
    end
  end
rescue LoadError
  class PlanioNotifier
    def self.show message, title = ""
      puts "Planio #{title}: #{message}"
    end
  end
end
