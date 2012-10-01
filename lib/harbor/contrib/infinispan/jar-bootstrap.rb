#!/usr/bin/env jruby

require "java"
require Pathname(__FILE__).dirname + "configuration"

cluster_name = 'test_cluster'
node_id = 1

manager = CacheManager.new(cluster_name, node_id)
translations = manager.translations
manager.wait_for_cluster_to_form

translations["message"] = "Waiting..."

if node_id == 1
  puts "What do you want to say?"
  while !(message = STDIN.gets).strip.empty? do
    translations["message"] = message
  end
  translations.clear
else
  while translations["message"] do
    puts translations["message"]
    sleep 5
  end
end
