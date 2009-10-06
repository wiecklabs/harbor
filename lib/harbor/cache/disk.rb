require Pathname(__FILE__).dirname.parent + "cache"

class Harbor::Cache::Disk

  def initialize(path)
    @path = path.is_a?(Pathname) ? path : Pathname(path)

    FileUtils.mkdir_p(@path) unless ::File.directory?(@path.to_s)
  end

  def get(key)
    if (path = filename_for_key(key))
      item_for_path(path)
    else
      nil
    end
  end

  alias [] get

  def put(key, ttl, maximum_age, content, cached_at)
    item = Harbor::Cache::Item.new(key, ttl, maximum_age, content, cached_at)

    FileUtils.rm(filenames_for_key(key))

    ::File.open(path_for_item(item), 'w') do |file|
      file.write(content)
    end

    item
  end

  def delete(key)
    if (path = filename_for_key(key))
      FileUtils.rm(path) rescue nil
    end
  end

  def delete_matching(key)
    filenames_for_key(key).each do |path|
      FileUtils.rm(path) rescue nil
    end
  end

  def bump(key)
    if item = get(key)
      current_path = path_for_item(item)

      item.bump

      new_path = path_for_item(item)
      FileUtils.mv(current_path, new_path) unless current_path == new_path
    end
  end

  private

  def filenames_for_key(key)
    if key.is_a?(Regexp)
      Dir[@path + "*"].select { |path| path[/.*?__INFO__/] =~ key }
    else
      Dir[@path + "c_#{key}.*"]
    end
  end

  def filename_for_key(key)
    filenames_for_key(key).first
  end

  def item_for_path(path)
    components = ::File.basename(path).split('.')

    return nil if components.size < 6

    expires_at = Time.parse(components.pop)
    cached_at = Time.parse(components.pop)

    if (maximum_age = components.pop).size > 0
      maximum_age = maximum_age.to_i
    else
      maximum_age = nil
    end

    if (ttl = components.pop).size > 0
      ttl = ttl.to_i
    else
      ttl = nil
    end

    key = components.reject { |c| c == "__INFO__" }.join('.').sub(/^c\_/, '')

    Harbor::Cache::Item.new(key, ttl, maximum_age, Pathname(path), cached_at, expires_at)
  end

  def path_for_item(item)
    @path + "c_#{item.key}.__INFO__.#{item.ttl}.#{item.maximum_age}.#{item.cached_at.strftime('%Y%m%dT%H%M%S%z')}.#{item.expires_at.strftime('%Y%m%dT%H%M%S%z')}"
  end

end