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
