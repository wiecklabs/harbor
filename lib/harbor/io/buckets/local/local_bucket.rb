require "pathname"
require Pathname(__FILE__).dirname + ".." + ".." + "bucket"

module Harbor

  module IO

    module Buckets

      module Local

        class LocalBucket < Harbor::IO::Bucket

          attr_reader :root

          def initialize(root, options = {})
            @root = root
            @public_url_base_address = options[:public_url_base_address] || ''
            @public_url_base_address = "#{@public_url_base_address}/" unless @public_url_base_address.size == 0 or @public_url_base_address =~ /\/$/
          end

          def absolute_path(relative_path = '')
            (Pathname(@root) + strip_leading_file_separator(relative_path)).to_s
          end

          def bytes(relative_path)
            relative_path = strip_leading_file_separator(relative_path)
            ::File.size(absolute_path(relative_path))
          end

          def copy_from_uri(relative_path, source_uri)
            relative_path = strip_leading_file_separator(relative_path)
            FileUtils.mkdir_p(::File.dirname(absolute_path(relative_path)))
            object = ::File.open(absolute_path(relative_path), 'wb')
            source = Harbor::IO::BucketManager.instance.open(source_uri)
            data = source.sysread(source.stat.size)
            object.syswrite(data)
            source.close
          end

          def delete(relative_path)
            ::File.delete(absolute_path(relative_path))
          end

          def directory?(relative_path)
            ::File.directory?(absolute_path(relative_path))
          end

          def exists?(relative_path)
            ::File.file?(absolute_path(relative_path))
          end

          def files(relative_path = '')
            Dir.new(absolute_path(relative_path)).entries.select { |entry|
              self.exists?(Pathname(relative_path) + entry)
            }.compact
          end

          def make_relative(absolute_path)
            strip_leading_file_separator(absolute_path.gsub(absolute_path(), ''))
          end

          def mkdir_p(relative_path)
            FileUtils.mkdir_p(absolute_path(relative_path))
          end

          def open(relative_path, mode = 'r', &block)
            if block_given?
              ::File.open(absolute_path(relative_path), mode, &block)
            else
              ::File.open(absolute_path(relative_path), mode)
            end
          end

          def public_url(relative_path)
            relative_path = strip_leading_file_separator(relative_path)
            "#{@public_url_base_address}#{relative_path}"
          end

          def save(relative_path, file)
            relative_path = strip_leading_file_separator(relative_path)
            FileUtils.mkdir_p(::File.dirname(absolute_path(relative_path)))
            object = ::File.open(absolute_path(relative_path), 'wb')
            data = file.sysread(file.stat.size)
            object.syswrite(data)
            file.close
            object.close
          end

          private

          def strip_leading_file_separator(relative_path)
            relative_path = relative_path[1..relative_path.size - 1] if relative_path =~ /^#{::File::SEPARATOR}/
            relative_path
          end

        end

      end

    end

  end

end