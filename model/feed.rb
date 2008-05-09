require 'timeout'
require 'open-uri'
require 'feed-normalizer'

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
    varchar   :etag
    text      :description
    boolean   :always, :default => false
    index [:handle], :unique => true
    index [:synced]
  end 

  #one_to_many :items, :key => :feed_id, :order => :id.DESC
  has_many :items

  include Validatable

  validates do 
    presence_of :url, :handle
    # FIXME: check the uniqueness of :handle
    # uniqueness_of :handle, :event => :create
    format_of :handle, :with => /^\w+$/, :message => "cannot contain whitespace"
  end

  after_create do
    update_values(:created => Time.now, :updated => Time.now)
  end

  after_update do
    update_values(:updated => Time.now)
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
  #
  def sync!(forceUpdate = false, giveup = Configuration.for('app').giveup)
    begin
      Timeout::timeout(giveup) do
        @opts = {}
        unless forceUpdate
          @opts = @opts.merge({'If-Modified-Since' => self.synced.to_formatted_s(:rfc822)}) if self.synced
          @opts = @opts.merge({'If-None-Match' => self.etag}) if self.etag
        end
        @data = open(self.url, @opts) 
      end
    rescue OpenURI::HTTPError
      update_values(:synced => Time.now, :status => 304)
      save if valid?
      return 304
    rescue Timeout::Error
      Ramaze::Log.error "[E] #{self.url} timeout error"
      return nil
    rescue => e
      Ramaze::Log.error "[E] #{e}"
      return nil
    else
      rss = FeedNormalizer::FeedNormalizer.parse(@data)
    end 

    # set the title, description and link ONLY IF EMPTY
    update_values(:title => rss.channel.title.to_s) unless self.title
    unless self.description
      update_values(:description => rss.channel.description ? rss.channel.description.to_s : self.title)
    end
    unless self.link
      update_values(:link => rss.channel.urls.first) if rss.channel.urls
    end

    # add only the uniq items (uniq GUID)
    rss.entries.reverse.each do |i|
      DB.transaction do
        guid = guid_for(i)
        next if Item[:guid=>guid]
        title = i.title.to_s.gsub(/<[a-zA-Z\/][^>]*>/,'')
        p title
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
    update_values(:synced => Time.now, :status => @data.status[0].to_i, :etag => @data.meta['etag'])
    save if valid?
    return @data.status[0].to_i
  end

private
  def guid_for(rss_entry)
    guid = rss_entry.urls.first
    guid = rss_entry.id.to_s if rss_entry.id
    return Digest::SHA1.hexdigest("--#{guid}--myBIGsecret")
  end

  def fix_content(content, site_link)
    content = CGI.unescapeHTML(content) unless /</ =~ content
    correct_urls(content, site_link)
  end
  
  def correct_urls(text, site_link)
    site_link += '/' unless site_link[-1..-1] == '/'
    text.gsub(%r{(src|href)=(['"])(?!http)([^'"]*?)}) do
      first_part = "#{$1}=#{$2}"
      url = $3
      url = url[1..-1] if url[0..0] == '/'
      "#{first_part}#{site_link}#{url}"
    end
  end

end

Feed.create_table unless Feed.table_exists?

if Feed.empty? && Configuration.for('app').bootstrap
  Feed.add('CNNTop', 'http://rss.cnn.com/rss/cnn_topstories.rss')
  Feed.add('Slashdot', 'http://rss.slashdot.org/Slashdot/slashdot')
  Feed.add('JoelOnSoftware', 'http://www.joelonsoftware.com/rss.xml')
  Feed.add('SchneierSecurity', 'http://www.schneier.com/blog/index.rdf')
end
