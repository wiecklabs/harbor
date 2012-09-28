class Harbor
  class FileStore

    require Pathname(__FILE__).dirname + "file_store/file"
    require Pathname(__FILE__).dirname + "file_store/local"
    
    @@registrations = []

    def self.register(name, store)
      @@registrations.push name
      file_stores[name] = store
    end

    def self.file_stores
      @@file_stores ||= {}
    end

    def self.[](name)
      file_stores[name]
    end
    
    def self.exists?(path)
      @@registrations.each do |registration|
        if file_stores[registration].exists?(path) == true
          return true
        end
      end
      false
    end
    
    def self.get(path)
      @@registrations.each do |registration|
        if file_stores[registration].exists?(path) == true
          return file_stores[registration].get(path)
        end
      end
      nil
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