class <@= app_class @>
  class Home < Harbor::Controller

    get "/" do
      render "home/index"
    end

  end
end
