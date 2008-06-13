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

class Numeric
  MINUTE = 60
  HOUR = 3600
  DAY = 86400
  WEEK = DAY * 7
  MONTH = WEEK * 4
  YEAR = MONTH * 12

  # Converts self from minutes to seconds
  def minutes;  self * MINUTE;  end; alias_method :minute, :minutes
  # Converts self from hours to seconds
  def hours;    self * HOUR;    end; alias_method :hour, :hours
  # Converts self from days to seconds
  def days;     self * DAY;     end; alias_method :day, :days
  # Converts self from weeks to seconds
  def weeks;    self * WEEK;    end; alias_method :week, :weeks
  # Converts self from months to seconds
  def months;   self * MONTH;   end; alias_method :month, :months
  # Converts self from years to seconds
  def years;    self * YEAR;    end; alias_method :year, :years

  # Returns the time at now - self.
  def ago(t = Time.now); t - self; end
  alias_method :before, :ago

  # Returns the time at now + self.
  def from_now(t = Time.now); t + self; end
  alias_method :since, :from_now
end unless defined? Numeric::MINUTE

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
