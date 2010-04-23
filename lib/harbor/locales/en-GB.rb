locale = Harbor::Locale.new
locale.culture_code        = 'en-GB'
locale.time_formats        = {:long => "%d/%m/%Y %h:%m:%s", :default => "%h:%m:%s"}
locale.date_formats        = {:default => '%d/%m/%Y'}
locale.decimal_formats     = {:default => "%8.2f", :currency => "$%8.2f"}
locale.wday_names          = [nil, 'Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
locale.wday_abbrs          = [nil, 'Sun', 'Mon', 'Tue', 'Wed', 'Thur', 'Fri', 'Sat']
locale.month_names         = [nil, 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'Steptember', 'October', 'November', 'December']
locale.month_abbrs         = [nil, 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'June', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
locale.meridian_indicator = {"AM" => "AM", "PM" => "PM"}
Harbor::Locale.register(locale)

