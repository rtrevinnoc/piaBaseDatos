require 'bundler'
Bundler.require

Envyable.load('./config/env.yml')

require './main.rb'
run Main.new
