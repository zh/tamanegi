#!/usr/bin/env ruby

# OS X speedup
require 'resolv-replace'

require 'rubygems'
require 'sequel'
require 'validatable'
require 'ramaze'

DB_FILE = File.join(File.dirname(__FILE__),"db","tamanegi.db")
DB = Sequel("sqlite:///#{DB_FILE}", :single_threaded => true)

acquire __DIR__/:lib/'*'
Kernel.load 'config.rb'

# require all controllers and models
acquire __DIR__/:model/'*'
acquire __DIR__/:controller/'*'

module Ramaze
  class Pager
    def navigation
      url=Request.current.env['PATH_INFO']
      nav = ""
      unless first_page?
        nav << %{
<a href="#{url}?_page=#{prev_page}">&lt;Prev</a>
<a href="#{url}?_page=#{first_page}">&lt;&lt;First</a>
        }
      end
      for i in nav_range()
        if i == @page
          nav << %{<span class="active">#{i}</span>&nbsp;}
        else
          nav << %{<a href="#{url}?_page=#{i}">#{i}</a>&nbsp;}
        end
      end
      unless last_page?
        nav << %{
 <a href="#{url}?_page=#{last_page}">Last&gt;&gt;</a>
 <a href="#{url}?_page=#{next_page}">Next&gt;</a>
        }
      end
      return nav
    end
  end
end

module Tamanegi
  def self.sync!(forceUpdate = false, debug = false)
    Feed.all.each { |f| 
      status = f.sync!(forceUpdate) 
      puts "#{Time.now.iso8601} #{f.url} [#{status}]" if (status && debug)
    }
    Item.vacuum!
  end
end

Tamanegi::sync!(true) if Item.empty? && Configuration.for('app').bootstrap 

if __FILE__ == $0
  Tamanegi::sync!(false,true)
end
