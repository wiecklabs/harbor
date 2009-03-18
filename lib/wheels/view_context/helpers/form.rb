module Wheels::ViewContext::Helpers::Form

  ##
  # Form helper which abstracts away setting necessary information:
  #   1. If no enctype is passed, and a file input is found, uses
  #      multipart/form-data.
  #   2. Creates a hidden input for setting _method when method option
  #      is put or delete.
  ##
  def form(action, options = {}, &block)
    method = options.delete(:method) || :post

    get = method == :get
    post = method == :post

    body = capture(&block)

    enctype = options.delete(:enctype) || (body =~ /\<input[^>]+?type\=["']file["']/ ? "multipart/form-data" : nil)

    with_buffer(block) do |buffer|
      buffer << "<form action=\"#{action}\" method=\"#{get ? "get" : "post"}\""
      buffer << " enctype=\"#{enctype}\"" if enctype
      buffer << " #{options.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")}" unless options.empty?
      buffer << ">"
      buffer.puts

      unless get || post
        buffer.puts "  <input type=\"hidden\" name=\"_method\" value=\"#{method}\">"
      end

      buffer << body
      buffer.puts "</form>"
    end

  end
end