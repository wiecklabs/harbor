locale = Harbor::Locale.new
locale.culture_code        = 'en-US'
locale.time_formats        = {:long => "%m/%d/%Y %h:%m:%s", :default => "%h:%m:%s"}
locale.date_formats        = {:default => '%m/%d/%Y'}
locale.decimal_formats     = {:default => "%B", :currency => "$%B", :percent => "%B%%"}
locale.wday_names          = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
locale.wday_abbrs          = %w(Sun Mon Tue Wed Thur Fri Sat)
locale.month_names         = %w{January February March April May June July August September October November December}
locale.month_abbrs         = %w{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
# locale.load Pathname("locales/en/us/strings.yml")

Harbor::Locale.register(locale)
