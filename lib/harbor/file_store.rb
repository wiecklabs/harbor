module Harbor
  class FileStore

    require Pathname(__FILE__).dirname + "file_store/file"
    require Pathname(__FILE__).dirname + "file_store/local"

    def self.register(name, store)
      file_stores[name] = store
    end

    def self.file_stores
      @@file_stores ||= {}
    end

    def self.[](name)
      file_stores[name]
    end

    def get(path)
      Harbor::FileStore::File.new(self, path)
    end

    def put(path, file)
      raise NotImplementedError.new("You must define your own implementation of FileStore#put")
    end

    def delete(path)
      raise NotImplementedError.new("You must define your own implementation of FileStore#delete")
    end

    def exists?(path)
      raise NotImplementedError.new("You must define your own implementation of FileStore#exists?")
    end

    def open(path)
      raise NotImplementedError.new("You must define your own implementation of FileStore#open")
    end

    def size(path)
      raise NotImplementedError.new("You must define your own implementation of FileStore#size")
    end

    ##
    # Defines whether a file store is local, and thus could be directly copied rather
    # than read and then written.
    ##
    def local?
      raise NotImplementedError.new("You must define your own implementation of FileStore#local?")
    end

  end
end