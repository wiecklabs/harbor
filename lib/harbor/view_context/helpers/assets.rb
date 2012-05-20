module Harbor::ViewContext::Helpers::Assets
  def javascript(*sources)
    sources.collect do |source|
      asset = asset_for(source, type: 'js')
      if asset
        if compile_assets?
          asset.to_a.map { |dependency| javascript_tag("#{asset_path(dependency)}?body=1") }
        else
          javascript_tag(asset_path(asset))
        end
      else
        source << ".js" unless source =~ /\.js$/
        source = "/#{source}" unless source =~ /^\// || source =~ /http(s)?:\/\//
        javascript_tag(source)
      end
    end.join("\n")
  end

  private

  def javascript_tag(path)
    "<script type=\"text/javascript\" src=\"#{path}\"></script>"
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
