class ItemController < Ramaze::Controller
  map '/'
  layout :layout
  deny_layout :atom
  helper :pager

  def index
    @title = "The state of the onion"
    @ids, @pager = paginate(Item.order(:id.desc).map(:id), 
                            :limit => Configuration.for('app').one_page)
  end

  def show title
    redirect Rs() unless @item = Item[:title => title.uri_unescape]
    @title = @item.title
  end

  # cached for 15 minutes
  def atom
    sup_id = Configuration.for('app').sup_id
    response['Content-Type'] = 'application/atom+xml'
    response['Cache-Control'] = 'max-age=900, public'
    response['Expires'] = (Time.now + 900).utc.rfc2822
    response['X-SUP-ID'] = "http://friendfeed.com/api/public-sup.json##{sup_id}"
    respond Tamanegi::to_atom.to_xml
  end

end
