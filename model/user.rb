class User < Sequel::Model(:users)
  set_schema do
    primary_key :id
    varchar :username
    varchar :password
    index [:username], :unique => true
  end

  include Validatable

  validates do
    presence_of :username, :password
    format_of :username, :with => /^\w+$/, :message => "cannot contain whitespace"
    format_of :password, :with => /^\w+$/, :message => "cannot contain whitespace"
  end
end

User.create_table unless User.table_exists?
User.create :username => 'admin', :password => 'admin123' if User.empty?
