require 'builder'

class ItemController < Ramaze::Controller
  map '/'
  layout :layout
  deny_layout :atom
  helper :pager, :cgi

  # the index action is called automatically when no other action is specified
  def index
    @title = "Aggregated news"
    @ids, @pager = paginate(Item.order(:id.DESC).map(:id), 
                            :limit => Configuration.for('app').one_page)
  end

  def show id
    @item = item_for(id)
    @title = @item.title
  end

  # TODO: provide :atom, :json, :xml etc. helper
  def atom
    @items = Item.order(:created.DESC).limit(Configuration.for('app').rss_page)
  end

private

  def item_for(id)
    redirect Rs() unless item = Item[:id => id.to_i]
    item
  end

end
