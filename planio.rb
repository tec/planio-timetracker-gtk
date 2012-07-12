require "rubygems"
require 'yaml'
require './planio_server.rb'
require './planio_menu.rb'

planio_config = YAML::load(File.read(File.join(ENV['HOME'], '.planio')))
planio_server = PlanioServer.new planio_config
planio_menu = PlanioMenu.new planio_server 
planio_menu.start

