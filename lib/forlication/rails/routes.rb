module ActionController::Routing
  class RouteSet

    # Want the Forlication modules included after loading routes
    def load_routes_with_forlication!
      load_routes_without_forlication!
      return if Forlication.mappings.empty?

      ActionController::Base.send :include, Forlication::Controllers::Helpers
      ActionController::Base.send :include, Forlication::Controllers::UrlHelpers

      ActionView::Base.send :include, Forlication::Controllers::UrlHelpers
    end
    alias_method_chain :load_routes!, :forlication

    class Mapper
      # This way the application using this engine can specify routing options by using
      # map.forlicate_at :path_prefix => 'path', ...
      def forlicate_at(*args)
        options = args.extract_options!

        resources = args.map!(&:to_sym)
        resources.each do |resource|
          mapping = Forlication::Mapping.new(resource, options.dup)
          Forlication.mappings[mapping.name] = mapping

          route_options = mapping.route_options

          with_options(route_options) do |routes|
            [:token_actionable].each do |mod|
              send(mod, routes, mapping) if self.respond_to?(mod, true)
            end
          end
        end
      end

      protected
      def token_actionable(routes, mapping)
        routes.send(mapping.name.to_sym, "#{mapping.raw_path}", mapping.route_options)
        if mapping.performer

          # Could also send this to ActionView::Base, but I don't think this
          # stuff should be in a view.
          
          ActionController::Base.class_eval <<-END
            def #{mapping.scope}_forlication_url(object)
              url_for #{mapping.route_options.inspect[1..-2]},
                      :#{mapping.token} => Forlication::Job.link(object, "#{mapping.scope}")
            end

            def #{mapping.scope}_forlication_path(object)
              url_for #{mapping.route_options.inspect[1..-2]},
                      :#{mapping.token} => Forlication::Job.link(object, "#{mapping.scope}"),
                      :only_path => true
            end
          END
        end
      end
    end
  end
end
