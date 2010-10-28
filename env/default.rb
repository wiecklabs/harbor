# Setup default locale.
config.register("locales", Harbor::Configuration.new)
config.locales.register("default", Harbor::Locale::default)

# Setup default cache.
tmp = Pathname(FileUtils::pwd) + "tmp" + "cache"
FileUtils::mkdir_p(tmp.to_s)
config.register("cache", Harbor::Cache.new(Harbor::Cache::Disk.new(tmp.to_s)))