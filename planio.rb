#!/usr/bin/env ruby
require "rubygems"
require 'yaml'
require './lib/planio_server.rb'
require './lib/planio_menu.rb'

planio_config = YAML::load(File.read(File.join(ENV['HOME'], '.planio/config')))
planio_server = PlanioServer.new planio_config
planio_menu = PlanioMenu.new planio_server 
planio_menu.start

