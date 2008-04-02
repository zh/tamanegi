#!/usr/bin/env ruby

require 'rubygems'
require 'ramaze'
require 'ostruct'
require 'sequel'
require 'validatable'
require 'rss-client'

DB_FILE = File.join(File.dirname(__FILE__),"db","tamanegi.db")
DB = Sequel("sqlite:///#{DB_FILE}")
Sequel.single_threaded = true

acquire __DIR__/:lib/'*'
Kernel.load 'app.rb'

# require all controllers and models
acquire __DIR__/:model/'*'
#acquire __DIR__/:controller/'*'

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
