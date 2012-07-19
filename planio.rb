#!/usr/bin/env ruby
require "rubygems"
require 'yaml'
require './lib/planio_tracker.rb'
require './lib/planio_server.rb'
require './lib/planio_menu.rb'

planio_tracker = PlanioTracker.new
planio_config = planio_tracker.get_config
planio_server = PlanioServer.new planio_config
planio_menu = PlanioMenu.new planio_server 
planio_menu.start

