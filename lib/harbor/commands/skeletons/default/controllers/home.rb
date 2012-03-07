class ##>=app_class<##
  class Home < Harbor::Controller

    index do
      response.render "home/index"
    end
    
  end
end