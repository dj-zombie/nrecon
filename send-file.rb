#!/usr/bin/env ruby
require 'rest-client' # https://github.com/rest-client/rest-client
require 'json'
require 'dotenv/load'
require 'uri'
require_relative 'login'

# Configuration
server =          ENV['SERVER']
autossh_server =  ENV['AUTOSSH_SERVER']
iface =           ENV['INTERFACE']
log =			        '/root/git/nrecon/log/'

p HPTOKEN

listener = Listen.to(log + ARGV[1]) do |modified, added, removed|
  unless modified.empty?
    puts "Modified: #{ modified[0] }"
      r = RestClient.put(server + '/agent-upload',
        ssid: ARGV[1],
        files: 
        {file: File.open(modified[0], 'r')})
          # {file_a: File.open('README.md', 'r'),
          # file_b: File.open('LICENSE', 'r')})
  end	
end