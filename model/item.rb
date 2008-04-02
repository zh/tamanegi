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

end

Item.create_table unless Item.table_exists?
