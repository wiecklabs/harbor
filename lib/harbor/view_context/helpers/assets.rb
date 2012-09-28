module Harbor::ViewContext::Helpers::Assets
  def javascript(*sources)
    with_assets('js', *sources) do |src|
      javascript_tag(src)
    end.join("\n")
  end

  def stylesheet(*sources)
    with_assets('css', *sources) do |src|
      stylesheet_tag(src)
    end.join("\n")
  end

  private

  def with_assets(type, *sources)
    sources.collect do |source|
      asset = asset_for(source, type)
      if asset
        if compile_assets?
          asset.to_a.map { |dependency| yield "#{asset_path(dependency)}?body=1" }
        else
          yield asset_path(asset)
        end
      else
        source << ".#{type}" unless source =~ /\.#{type}$/
        source = "/#{source}" unless source =~ /^\// || source =~ %r{^[-a-z]+://|^cid:|^//}
        yield source
      end
    end
  end

  def javascript_tag(path)
    "<script type=\"text/javascript\" src=\"#{path}\"></script>"
  end

  def stylesheet_tag(path)
    "<link href=\"#{path}\" rel=\"stylesheet\" type=\"text/css\"/>"
  end

  def asset_for(source, ext)
    config.assets.find_asset(source, ext)
  end

  def asset_path(asset)
    config.assets.asset_path(asset)
  end

  def compile_assets?
    config.assets.compile
  end
end
