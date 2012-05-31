class Harbor
  class TemplateLookup
    attr_reader :paths

    def initialize(paths = [])
      @paths = paths
    end

    def find(template_name, options = {})
      result = try_find(template_name, options)
      unless result
        raise "Could not find '#{template_name}' in #{paths.map(&:to_s)}"
      end
      result
    end

    def exists?(template_name, options = {})
      !!try_find(template_name, options)
    end

    private

    def try_find(template_name, options)
      return nil if paths.empty?

      preferred_formats = options.fetch(:preferred_formats, ['html'])
      format, engine    = extract_format_and_engine(template_name)

      file_pattern = template_name.dup
      file_pattern << ".{#{preferred_formats.join(',')}}" unless format
      # TODO: Do we really need to glob for available engines or just use a wildcard?
      file_pattern << engines_glob unless engine
      file_pattern = "#{paths_glob}/**/#{file_pattern}"

      template_matches = Dir[file_pattern]

      if template_matches.size > 0
        full_path = template_matches.first
        [format || format_from_file_name(full_path), full_path]
      end
    end

    def paths_glob
      @paths_glob ||= "{#{paths.join(',')}}"
    end

    def engines_glob
      @engines_glob ||= ".{#{engines.join(',')}}"
    end

    def format_from_file_name(full_path)
      full_path.match(/\.(\w+)\.\w+$/)[1]
    end

    def extract_format_and_engine(template_name)
      parts = template_name.split('.')
      engine, format = nil, nil

      if parts.size > 1
        engine = parts.pop if engines.include?(parts.last)
        format = parts.last if parts.size > 1
      end

      [format, engine]
    end

    def engines
      @engines ||= Tilt.mappings.keys
    end
  end
end
