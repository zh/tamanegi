#!/usr/bin/env ruby

# OS X speedup
require 'resolv-replace'

require 'rubygems'
require 'validatable'
require 'sequel'

$LOAD_PATH.unshift(File.dirname(__FILE__))

DB_FILE = File.join(File.dirname(__FILE__),"db","tamanegi.db")
DB = Sequel("sqlite:///#{DB_FILE}", :single_threaded => true)

class Dir
  def self.scan(directory)
    self.entries(directory).each do |file|
      if file =~ /\.rb/
        require directory + file
      end
    end
  end
end

Dir.scan("lib/")
Kernel.load 'config.rb'

# require all controllers and models
Dir.scan("model/")

module Tamanegi
  def self.sync!(forceUpdate = false, debug = false)
    Feed.all.each { |f| 
      status = f.sync!(forceUpdate) 
      puts "#{Time.now.iso8601} #{f.url} [#{status}]" if (status && debug)
    }
  end
end

Tamanegi::sync!(true) if Item.empty? && Configuration.for('app').bootstrap 

if __FILE__ == $0
  Tamanegi::sync!(false,true)
end
