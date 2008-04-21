require 'atom/pub'

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

  belongs_to :feed

  subset(:old_items) {:created < 30.days.ago}

  def self.vacuum!
    old_items.delete
  end

  after_create do
    set(:created => Time.now)
  end

  def to_atom
    cfg = Configuration.for('app')
    Atom::Entry.new do |e|
      e.id         = "#{cfg.base_url}/show/#{self.id}"
      e.title      = self.title
      e.updated    = self.created
      e.published  = self.created
      # e.authors   << Atom::Person.new(:name => cfg.author.name)
      e.links     << Atom::Link.new(:rel => 'alternative', :href => "#{cfg.base_url}/show/#{self.id}")
      e.content    = Atom::Content::Html.new(self.description)
    end
  end

end

Item.create_table unless Item.table_exists?
