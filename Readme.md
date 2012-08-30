An Ubuntu/Unity App Indicator for Time Tracking with Planio
===========================================================

Features
--------

A small applet for Ubuntu/Unity users to do time tracking on your Planio/Redmine projects and tasks.

Usage
-----

Click on the application indicator and choose a project or ticket to start time tracking. Click stop when you are finished or click on the next task to start with the next task. If there is another project/tasks tracking time it will be stopped. All the times will be stored locally until you upload them.

<img src="https://raw.github.com/tec/planio-timetracker-gtk/master/media/screenshot.png" alt="Usage sample of planio-timetracker-gtk with the menu and several projects open."></img>

Install Notes
-------------

Use https://rvm.io/
Install dependencies (ruby-libappindicator is required, libnotify is optional for notifications):

<pre><code>
sudo apt-get install libappindicator-dev libinotify-ruby libgtk2-ruby libnotify-dev;
gem install ruby-libappindicator
gem install libnotify
</code></pre>

Configure your plan.io (or redmine or derivate like chiliproject):
Check that the rest api is enabled on the authentication tab on https://pidoco.plan.io/settings
Find your apikey on the right side panel on https://pidoco.plan.io/my/account

Create the folder .planio in your home dir and a file called .planio/config with two lines:

<pre><code>
domain: your_team.plan.io
apikey: your_api_key
</code></pre>

Check it out and try running it:

<pre><code>
git clone git@github.com:tec/planio-timetracker-gtk.git
cd planio-timetracker-gtk
./planio.rb
</code></pre>

You might want to put it into your autostart.

What about Redmine, Chiliproject, etc.?
---------------------------------------

It probably works in any redmine installation. I only tested it with http://plan.io . Patches welcome.

What about Gnome, KDE, etc.?
---------------------------------------

It probably won't work in other desktop environments out of the box. However it will probably be quite easy to be fixed if you have gtk installed. Have a look on lib/planio_menu.rb in the constructor of the PlanioMenu class. You'll probably want to create something else than AppIndicator. Patches welcome. Same applies to other Linux distributions.

License
-------

Fork it and do whatever you want. Merge requests, feature ideas, bug reports, thank you emails are welcome.

