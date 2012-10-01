require "thread"
require "logger"

class ClusterValidation
  
  include_package "java.lang"
  include_package "org.infinispan"
  include_package "org.infinispan.manager"
  include_package "org.infinispan.util.logging"
  
  REPLICATION_TRY_COUNT = 60
  REPLICATION_TIME_SLEEP = 2
  KEY = self.name
  LOG = Logger.new(STDOUT)
  
  def self.wait_for_cluster_to_form(cache_manager, node_id, cluster_size)

    self.new(cache_manager.get_cache, node_id, cluster_size).check_replication_several_times > 0
  end

  def initialize(cache, node_id, cluster_size)
    @cache = cache
    @node_id = node_id
    @cluster_size = cluster_size
  end

  def check_replication_several_times
    REPLICATION_TRY_COUNT.times do
      try_to_put
      sleep REPLICATION_TIME_SLEEP
      current_replication_count = replication_count(@cluster_size)
      if current_replication_count == @cluster_size - 1
        LOG.info "Cluster formed successfully!"
        try_to_put
        return current_replication_count
      end
    end
    LOG.warn "Cluster failed to form!"
    -1
  end
    
  private

  def key(slave_index)
    KEY + slave_index.to_s
  end

  def try_to_put
    5.times do
      begin
        @cache.put(key(@node_id), "true")
        return nil
      rescue Throwable
      end
    end
    raise IllegalStateException.new "Couldn't accomplish addition before replication!"
  end

  def replication_count(cluster_size)
    replica_count = 0
    cluster_size.times do |i|
      next if i == @node_id
      if try_get i
        replica_count += 1
      end
    end
    replica_count
  end

  def try_get(member_node_id)
    5.times do
      return true if @cache.get(key member_node_id)
    end
    nil
  end
end
