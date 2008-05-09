class FeedController < Ramaze::Controller

  map '/feed'
  layout :layout => [ :index, :new, :edit ]

  helper :pager, :aspect, :auth

  before(:index,:new,:create,:edit,:update,:destroy,:sync) { login_required }

  def index
    @title = "Feeds"
    @feeds = Feed.order(:id.desc)
  end

  def new
    @title = "Create New Feed"
  end

  def create
    Feed.add(*request[:handle,:url]).sync!(true)
  end

  def edit id
    @feed = feed_for(id)
    @title = 'Edit: ' + @feed.handle 
  end

  def update
    feed = feed_for(request[:id])
    feed.update(*request[:handle, :url, :title, :description]).sync!(true)
  end

  def destroy id
    feed = feed_for(id)
    feed.items.delete
    feed.delete
  end

  def sync id
    ('all' == id) ? Tamanegi::sync! : feed_for(id).sync!
  end

  before(:create, :update) { redirect_referer unless request.post? }
  after(:create, :update, :destroy, :sync){ redirect Rs() }


private

  def feed_for(id)
    redirect_referer unless feed = Feed[:id => id.to_i]
    feed
  end

  def login_required
    flash[:error] = 'login required to view that page' unless logged_in?
    super
  end

  def check_auth user, pass
    return false if (not user or user.empty?) and (not pass or pass.empty?)

    if User[:username => user, :password => pass].nil?
      flash[:error] = 'invalid username or password'
      false
    else
      true
    end
  end

end
