require 'atom/pub'

class ItemController < Ramaze::Controller
  map '/'
  layout :layout
  deny_layout :atom
  helper :pager, :cgi

  # the index action is called automatically when no other action is specified
  def index
    @title = "The state of the onion"
    @ids, @pager = paginate(Item.order(:id.DESC).map(:id), 
                            :limit => Configuration.for('app').one_page)
  end

  def show id
    @item = item_for(id)
    @title = @item.title
  end

  # TODO: provide :atom, :json, :xml etc. helper
  def atom
    cfg = Configuration.for('app')
    @items = Item.order(:created.DESC).limit(cfg.rss_page)
    @feed  = Atom::Feed.new do |feed|
      feed.title   = cfg.title
      feed.id      = "#{cfg.base_url}/"
      feed.updated = Item.order(:id).last.created.iso8601
      feed.links  << Atom::Link.new(:rel=>"self", 
                                   :href=>"#{cfg.base_url}/atom", 
                                   :type=>"application/atom+xml")
      feed.links  << Atom::Link.new(:rel => 'alternate', 
                                   :href => "#{cfg.base_url}/")
      
      @items.each do |item|
        feed.entries << item.to_atom
      end
    end
    respond @feed.to_xml
  end

private

  def item_for(id)
    redirect Rs() unless item = Item[:id => id.to_i]
    item
  end

end
