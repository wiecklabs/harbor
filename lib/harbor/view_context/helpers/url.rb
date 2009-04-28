##
# Generic URL helpers, such as merging query strings.
##
module Harbor::ViewContext::Helpers::Url
  ##
  # Takes a query string and merges the provided params returning a new query string.
  ##
  def merge_query_string(query_string, params = {})
    Rack::Utils::build_query(Rack::Utils::parse_query(query_string).merge(params))
  end
end