# Todo: rewrite
module Snowball
  class Config
    def initialize(config = {})
      @config = config
      @config[:transforms] ||= []
      @config[:extensions] ||= []
      @config[:source_paths] ||= []
      @config[:raw] ||= []
      @config[:source] ||= []
      @config[:includes] ||= []
      @config[:ignores] = []
      @config[:env] ||= {}
      @config[:external] ||= []
      yield self
    end

    def http_path(path)
      @config[:http_path] = path
    end

    def source_path(path)
      @config[:source_paths] << File.expand_path(path)
    end

    def raw(glob_string)
      @config[:raw] << glob_string
    end

    def source(glob_string)
      @config[:source] << glob_string
    end

    def ignore(node_module)
      @config[:ignores] << node_module
    end

    def setenv(*args)
      @config[:env].merge!(args.first) and return if args.size == 1
      @config[:env][args.first] = args[1]
    end

    def include(node_module)
      @config[:includes] << node_module
    end

    def prelude(bool)
      @config[:prelude] = bool
    end

    def transforms(transforms)
      @config[:transforms] = transforms
    end

    def extensions(ext)
      @config[:extensions] = ext
    end
  end
end