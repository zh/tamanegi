require 'atom/pub'
require 'memcache'

CACHE = MemCache.new 'localhost:11211', :namespace => 'tamanegi' if Configuration.for('app').cache_items

class Item < Sequel::Model(:items)
  set_schema do
    primary_key :id
    foreign_key :feed_id, :table => :feeds
    varchar   :title
    varchar   :link
    varchar   :guid
    text      :description
    timestamp :created
    index [:guid], :unique => true
    index [:created]
  end

  set_cache CACHE, :ttl => 3600 if Configuration.for('app').cache_items

  belongs_to :feed, :order => :id.desc

  def self.vacuum!
    Item.filter(:created < 30.days.ago).delete
  end

  after_create do
    update_values(:created => Time.now)
  end

  def to_atom(base_url = Configuration.for('app').base_url)
    Atom::Entry.new do |e|
      e.id         = "urn:uuid:#{self.guid}"
      e.authors   << Atom::Person.new(:name => self.feed.handle)
      e.title      = self.title
      e.updated    = self.created
      e.published  = self.created
      e.links     << Atom::Link.new(:rel => 'alternate', 
                                    :href => "#{base_url}/show/#{self.title.uri_escape}")
      e.content    = Atom::Content::Html.new(self.description)
    end
  end

end

Item.create_table unless Item.table_exists?
