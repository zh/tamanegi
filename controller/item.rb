class ItemController < Ramaze::Controller
  map '/'
  layout :layout
  deny_layout :atom
  helper :pager, :cgi

  def index
    @title = "The state of the onion"
    @ids, @pager = paginate(Item.order(:id.desc).map(:id), 
                            :limit => Configuration.for('app').one_page)
  end

  def show title
    redirect Rs() unless @item = Item[:title => url_decode(title)]
    @title = @item.title
  end

  # cached for 15 minutes
  def atom
    response['Content-Type'] = 'application/atom+xml'
    response['Cache-Control'] = 'max-age=900, public'
    response['Expires'] = (Time.now + 900).utc.rfc2822
    respond Tamanegi::to_atom.to_xml
  end

end
