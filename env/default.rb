# Setup default locale.
config.locales = Harbor::Configuration.new
config.locales.default = Harbor::Locale::default

# Setup default cache.
tmp = Pathname(FileUtils::pwd) + "tmp" + "cache"
FileUtils::mkdir_p(tmp.to_s)
config.cache = Harbor::Cache.new(Harbor::Cache::Disk.new(tmp.to_s))