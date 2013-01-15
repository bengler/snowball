# Todo: rewrite
module Snowball
  class Config
    class Builder
      def initialize(config)
        @config = config
      end
      def http_path(path)
        @config.http_path = path
      end
      alias_method :set_serve_path, :http_path # todo: deprecate
      def source_path(path)
        @config.source_paths << File.expand_path(path)
      end

      alias_method :add_load_path, :source_path # todo: deprecate
      def raw(glob_string)
        @config.raw << glob_string
      end

      def ignore(node_module)
        @config.ignores << node_module
      end

      def setenv(*args)
        @config.env.merge!(args.first) and return if args.size == 1
        @config.env[args.first] = args[1]
      end

      def include(node_module)
        @config.includes << node_module
      end

      def prelude(bool)
        @config.prelude = bool
      end
    end

    attr_accessor :http_path, :source_paths, :raw, :extensions, :includes, :ignores, :prelude, :env

    def initialize
      @extensions = [:js, :coffee]
      @source_paths = []
      @raw = []
      @includes = []
      @ignores = []
      @env = {}
      @prelude = true
    end
  end
end
