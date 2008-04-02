require 'rss-client'

class Feed < Sequel::Model(:feeds)

  set_schema do
    primary_key :id 
    varchar   :url
    varchar   :title
    varchar   :link
    varchar   :handle, :size => 64, :unique => true 
    integer   :status
    time      :created
    time      :updated
    time      :synced
    text      :description
    boolean   :always, :default => false
    index [:handle], :unique => true
    index [:synced]
  end 

  one_to_many :items, :key => :feed_id

  include Validatable
  include RSSClient

  validates do 
    presence_of :url, :handle
    # FIXME: check the uniqueness of :handle
    # uniqueness_of :handle, :event => :create
    format_of :handle, :with => /^\w+$/, :message => "cannot contain whitespace"
  end

  after_create do
    set(:created => Time.now, :updated => Time.now)
  end

  after_update do
    set(:updated => Time.now)
  end

  def self.add(handle, url)
    create :handle => handle, :url => url
  end

  def update(handle = handle, url = url, title = title, description = description)
    self.handle, self.url, self.title, self.description = handle, url, title, description
    save if valid?
  end

  #
  # return status code
  # or nil on failure
  # OPTIMIZE: the current code is too complicated, maybe use open-uri instead
  #
  def sync!(forceUpdate = false, giveup = Configuration.for('app').giveup)
    opts = OpenStruct.new
    opts.forceUpdate = forceUpdate
    opts.giveup = giveup
    opts.since = self.synced if self.synced

    rss = get_feed(self.url, opts)
    return nil unless @rssc_raw             # feed not fetched
    set(:synced => Time.now, :status => @rssc_raw.status)
    save if valid?                          # Save the status
    return 304 if @rssc_raw.status == 304   # not modified
    return nil unless rss                   # feed not parsed

    # set the title, description and link ONLY IF EMPTY
    set(:title => rss.channel.title.to_s) unless self.title
    unless self.description
      set(:description => rss.channel.description ? rss.channel.description.to_s : self.title)
    end
    unless self.link
      set(:link => rss.channel.urls.first) if rss.channel.urls
    end

    # add only the uniq items (uniq GUID)
    rss.entries.reverse.each do |i|
      DB.transaction do
        guid = guid_for(i)
        next if Item[:guid=>guid]
        title = i.title.to_s
        item = Item.create(
          :title => title,
          :link => i.urls.first,
          :description => fix_content(i.content||i.description||i.summary, self.link),
          :guid => guid
        )
        item.feed = self
        item.valid? ? item.save : rollback
      end
    end
    save if valid?
    return @rssc_raw.status
  end
end

Feed.create_table unless Feed.table_exists?

if Feed.empty? && Configuration.for('app').bootstrap
  Feed.add('CNNTop', 'http://rss.cnn.com/rss/cnn_topstories.rss')
  Feed.add('Slashdot', 'http://rss.slashdot.org/Slashdot/slashdot')
  Feed.add('JoelOnSoftware', 'http://www.joelonsoftware.com/rss.xml')
  Feed.add('SchneierSecurity', 'http://www.schneier.com/blog/index.rdf')
end
