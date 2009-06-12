require 'singleton'

module Harbor

  module IO

    class BucketManager
      include Singleton

      @@buckets = Hash.new

      # Registers the specified bucket for later retrieval or access via uri.
      def register(name, bucket)
        @@buckets[name.to_s] = bucket
      end

      # Gets the previously registered bucket by name.
      def bucket(name)
        @@buckets[name.to_s]
      end

      def bytes(uri)
        (bucket, path) = parse_uri(uri)
        bucket.bytes(path)
      end

      def copy(source_uri, target_uri)
        (target_bucket, target_path) = parse_uri(target_uri)
        target_bucket.copy_from_uri(target_path, source_uri)
      end

      def delete(uri)
        (bucket, path) = parse_uri(uri)
        bucket.delete(path)
      end

      def exists?(uri)
        (bucket, path) = parse_uri(uri)
        bucket.exists?(path)
      end

      def mkdir_p(uri)
        (bucket, path) = parse_uri(uri)
        bucket.mkdir_p(path)
      end

      def move(source_uri, target_uri)
        (target_bucket, target_path) = parse_uri(target_uri)
        target_bucket.copy_from_uri(target_path, source_uri)
        delete(source_uri)
      end

      def open(uri)
        (bucket, path) = parse_uri(uri)
        bucket.open(path)
      end

      def path(uri)
        (bucket, path) = parse_uri(uri)
        path
      end

      def public_url(uri)
        (bucket, path) = parse_uri(uri)
        bucket.public_url(path)
      end

      def save(uri, file)
        (bucket, path) = parse_uri(uri)
        bucket.save(path, file)
      end

      private

      def parse_uri(uri)
        match = /^(\w*):\/\/(.*)$/.match(uri)
        bucket_name = match[1].to_s
        path = match[2].to_s
        bucket = bucket(bucket_name)
        raise "InvalidBucketUriException", "Bucket not found: #{bucket_name}" if bucket.nil?
        [bucket, path]
      end

    end

  end

end