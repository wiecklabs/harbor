class Session
  def initialize(request)
    @request = request
  end

  def [](key)
    @request.env["rack.session"][key]
  end

  def []=(key, value)
    @request.env["rack.session"][key] = value
  end

  def delete(key)
    @request.env["rack.session"].delete(key)
  end
end