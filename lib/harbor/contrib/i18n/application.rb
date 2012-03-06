module Harbor

  module Contrib

    module I18N

      class Application < Harbor::Application
        include Newsroom::Authorization

        def self.cascade
          [self]
        end

        def self.asset_path
          Pathname(__FILE__).dirname.parent.parent.expand_path + "assets"
        end

        def self.initialize!
          Newsroom.initialize!
          Harbor::View::path.unshift(Pathname(__FILE__).dirname + 'views')

          redis = Redis.new
          backend = I18n::Backend::KeyValue.new(redis)
          Harbor::Contrib::Translations::Translation.add_backend(backend)
        end

        def self.routes(services)

          Harbor::Router.new do
            using Controllers::Translations, config do |translations|
              get('/admin/translations') do |request, response|
                translations.index
              end
            end
          end

        end

      end
    end

  end

end
