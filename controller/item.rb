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

  def atom
    respond Tamanegi::to_atom.to_xml
  end

private

  def item_for(id)
    redirect Rs() unless item = Item[:id => id.to_i]
    item
  end

end
