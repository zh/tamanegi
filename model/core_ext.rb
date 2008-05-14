begin
  require 'json/ext'
rescue LoadError
  require 'json/pure'
end

class String#:nodoc:
  # Encodes a normal string to a URI string.
  def uri_escape
    gsub(/([^ a-zA-Z0-9_.-]+)/n) {'%'+$1.unpack('H2'*$1.size).join('%').upcase}.tr(' ', '+')
  end
  # Decodes a URI string to a normal string.
  def uri_unescape
    tr('+', ' ').gsub(/((?:%[0-9a-fA-F]{2})+)/n){[$1.delete('%')].pack('H*')}
  end
end

# shameless Rails copy-paste
class Time#:nodoc:

  DATE_FORMATS = {
    :db     => "%Y-%m-%d %H:%M:%S",
    :short  => "%d %b %H:%M",
    :long   => "%B %d, %Y %H:%M",
    :rfc822 => "%a, %d %b %Y %H:%M:%S %z"
  }

  def to_formatted_s(format = :default)
    DATE_FORMATS[format] ? strftime(DATE_FORMATS[format]).strip : to_s
  end
end

module Sequel#:nodoc:
  class Model
    def to_json
      self.values.to_json
    end

    def to_yaml
      YAML.dump(self.values)
    end
  end
end
