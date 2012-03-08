class <@= app_class @>
  class Home < Harbor::Controller

    get "/" do
      response.render "home/index"
    end

  end
end
