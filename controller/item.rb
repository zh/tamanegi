class ItemController < Ramaze::Controller
  map '/'
  layout :layout
  deny_layout :atom
  helper :pager, :cgi

  def index
    @title = "The state of the onion"
    @ids, @pager = paginate(Item.order(:id.DESC).map(:id), 
                            :limit => Configuration.for('app').one_page)
  end

  def show title
    redirect Rs() unless @item = Item[:title => url_decode(title)]
    @title = @item.title
  end

  def atom
    respond Tamanegi::to_atom.to_xml
  end

end
