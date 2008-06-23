#!/usr/bin/env ruby

# OS X speedup
require 'resolv-replace'

require 'rubygems'
require 'sequel'
require 'validatable'
require 'ramaze'
require 'atom/pub'

Sequel.use_parse_tree = false

DB_FILE = __DIR__/'db/tamanegi.db'
DB = Sequel.connect("sqlite://#{DB_FILE}")

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

  def self.to_atom(base_url = Configuration.for('app').base_url)
    cfg = Configuration.for('app')
    @items = Item.order(:created.desc).limit(cfg.rss_page)
    Atom::Feed.new do |feed|
      feed.title   = cfg.title
      feed.id      = "urn:uuid:"+Digest::SHA1.hexdigest("--#{base_url}--myBIGsecret")
      feed.updated = Item.order(:id).last.created.iso8601
      feed.authors << Atom::Person.new(:name => 'Aggregated Feed')
      feed.links  << Atom::Link.new(:rel=>"self",
                                   :href=>"#{base_url}/atom",
                                   :type=>"application/atom+xml")
      feed.links  << Atom::Link.new(:rel => 'alternate',
                                   :href => "#{base_url}/")

      @items.each do |item|
        feed.entries << item.to_atom(base_url)
      end
    end
  end
end

Tamanegi::sync!(true) if Item.empty? && Configuration.for('app').bootstrap 

if __FILE__ == $0
  Tamanegi::sync!(false,true)
end
