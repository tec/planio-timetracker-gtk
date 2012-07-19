#!/usr/bin/env ruby
require "rubygems"
require 'yaml'
require './lib/planio_tracker.rb'
require './lib/planio_server.rb'
require './lib/planio_menu.rb'

planio_tracker = PlanioTracker.new
planio_server = PlanioServer.new planio_tracker
planio_menu = PlanioMenu.new planio_tracker, planio_server
planio_menu.start

