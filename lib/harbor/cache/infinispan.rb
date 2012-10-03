Dir[Pathname(__FILE__).dirname.parent + 'contrib/infinispan/jar_files/*.jar'].each { |jar| require jar }

require "digest/md5"
require "java"

require Pathname(__FILE__).dirname.parent + 'contrib/infinispan/cluster_validation'

class Harbor::Cache::Infinispan

  include_package "java.lang"  
  include_package "org.infinispan.manager"
  include_package "org.infinispan.config"
  include_package "org.infinispan.configuration.global"
  include_package "org.infinispan.configuration.cache"

  # EVICTION NOTES:
  # LIRS is the default strategy when an eviction with max-entries is set, per
  #   https://docs.jboss.org/author/display/ISPN/Eviction#Eviction-Configurationanddefaultsin5.1.x
  #
  # So we don't have to worry about setting the strategy through JRuby (which is
  # a problem for some reason as the JRuby::JavaObject reference to the
  # Eviction::LIRS Enum isn't typecast properly).
  #
  # If we want LIRS, just set the max_entries. If you don't want to enable eviction, then
  # either don't make the call to #eviction, or set max_entries to 0 instead.

  CLUSTER_SIZE = 2

  def initialize(cluster_name, node_id)
    @node_id = node_id
    @default = ConfigurationBuilder.new.clustering.cache_mode(CacheMode::REPL_SYNC).l1.build

    base_port = (Digest::MD5.hexdigest(cluster_name).to_i(16) % 4000) + 26000
    System.properties["jgroups.tcp.port"] = "#{base_port}"
    System.properties["jgroups.tcpping.initial_hosts"] = "localhost[#{base_port}],localhost[#{base_port + 1}]"

    @manager = DefaultCacheManager.new(GlobalConfigurationBuilder.default_clustered_builder.transport.cluster_name(cluster_name).rack_id(ENV["ENVIRONMENT"]).machine_id(node_id.to_s).build, @default)

    @manager.define_configuration "translation", ConfigurationBuilder.new.read(@default).eviction.max_entries(10).build

    @translations = @manager.get_cache("translation")

  end

  def wait_for_cluster_to_form
    if !ClusterValidation.wait_for_cluster_to_form(@manager, @node_id, CLUSTER_SIZE)
      raise StandardError.new(
        "Error forming cluster, check the log"
      )
    end
  end

  def translations
    @translations
  end
end
