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
end