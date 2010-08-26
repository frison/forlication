module Forlication
  class Mapping
    attr_reader :token, :name, :path_prefix, :route_options, :action_class, :controller, :scope, :performer

    def self.find_by_path(path)
      split_path = path.split("/")
      Forlication.mappings.each_value do |mapping|
        path_prefix = split_path[0..mapping.token_position-1].join("/") + "/"
        return mapping if path_prefix == mapping.path_prefix
      end
    end

    def initialize(name, options)
      @token = (options.delete(:token) || :token).to_sym
      @name = (options.delete(:scope) || name.to_s.singularize).to_sym
      @scope = @name
      @performer = (options.delete(:performer) || false)

      # Ignore the action_class if this is going to be a 'performing' link
      @action_class = (options.delete(:action_class) || "Forlication").constantize if !performer

      @path_prefix = "/#{options.delete(:path_prefix)}/".squeeze("/")
      @route_options = {:action => 'show',
                        :controller => 'forlication'}.merge(options || {})
    end

    def raw_path
      path_prefix + ":#{token.to_s}"
    end

    def token_position
      self.path_prefix.count("/")
    end
  end
end
