module KeyValueMixin

  def keys(locale = nil)
    @store.keys("#{locale}*")
  end

end
       
