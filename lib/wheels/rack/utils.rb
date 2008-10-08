module Rack
  module Utils
    def parse_query(qs, d = '&;')
      params = {}
      (qs || '').split(/[#{d}] */n).each do |param|
        keys, value = unescape(param).split("=", 2)
        keys = keys.scan /[^\[\]]+|(?=\[\])/
        key = keys.pop
        if key.empty?
          key = keys.pop
          hash = keys.inject(params) { |h, k| h[k] ||= {} }
          hash[key] ||= []
          hash[key] << value
        else
          hash = keys.inject(params) { |h, k| h[k] ||= {} }
          hash[key] = value
        end
      end
      params
    end
    module_function :parse_query
  end
end