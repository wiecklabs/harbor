require_relative 'boot'

require 'harbor/router/descriptor'

routes = Harbor::Router::Descriptor::collect_routes

longest_path = routes.max { |a, b| a[:path].size <=> b[:path].size }
path_padding = longest_path[:path].size

longest_verb = routes.max { |a, b| a[:verb].size <=> b[:verb].size }
verb_padding = longest_verb[:verb].size

routes.each do |route|
  out = sprintf "%<verb>-#{verb_padding}s %<path>-#{path_padding}s %<controller>s", route
  puts out
end
