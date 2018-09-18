#!/usr/bin/env ruby
require 'rest-client' # https://github.com/rest-client/rest-client
require 'listen'
require 'json'
require 'dotenv/load'
require 'uri'
require 'whirly'
require 'paint'
require_relative 'login'

# Configuration
Whirly.configure spinner: "random_dots"
server =          ENV['SERVER']
autossh_server =  ENV['AUTOSSH_SERVER']
iface =           ENV['INTERFACE']
log =			        '/root/git/nrecon/log/'
`mkdir -p #{ log + ARGV[0] }`
p HPTOKEN
system("clear")

listener = Listen.to('log') do |modified, added, removed|
  unless modified.empty?
    puts "Modified #{ modified[0] }"
    r = RestClient.put(server + '/agent-upload',
      ssid: ARGV[0],
      files: 
      {file: File.open(modified[0], 'r')})
    sleep 1
    puts "Server response: #{ r }"
  end	
end

listener.start

loop do
  Whirly.start do
    Whirly.status = "Listening to #{ ARGV[0] }"
    sleep 60
  end
end
