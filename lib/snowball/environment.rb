module Snowball
  class Environment
    class InvalidOptionError < StandardError; end
    DEFAULTS = {
        source_path: -> { nil },
        http_path: -> { nil },
        extensions: -> { [:js] },
        debug: -> { false },
        transforms: -> { [] },
        raw: -> { false },
        source: -> { false },
        includes: -> { [] },
        noparse: -> { [] },
        env: -> { {} },
        external: -> { false },
    }
    OPTIONS = DEFAULTS.keys

    def initialize(parent=nil, &block)
      @parent = parent
      @config = {}
      @bundles = {}
      instance_exec(self, &block) if block_given?
    end

    # @param pattern fnmatch pattern to match source file against. Must be relative from source path
    # @param block configuration block
    def match(pattern, &block)
      if @parent
        raise NoMethodError, "undefined method `match' for #{to_s}. Can only specify bundles in toplevel environments."
      end
      @bundles[pattern] = Environment.new(self, &block)
      @bundles[pattern]
    end

    def for(path)
      @bundles.each_pair do |pattern, env|
        return env if File.fnmatch(pattern, path)
      end
      self
    end

    def to_s
      "<#{self.class}: #{@config.inspect}>"
    end

    def to_h
      @parent ? @parent.to_h.merge(@config) : @config.dup
    end

    def set(option, val)
      if @parent
        # Special case if this is a child environment. Doesn't make sense to specify http_path or source_path
        if option == :http_path
          raise InvalidOptionError, "Child environments cannot have their `http_path' overridden"
        elsif option == :source_path
          raise InvalidOptionError, "Child environments cannot have their `source_path' overridden"
        end
      end
      @config[option] = val
    end

    def get(option)
      return @config[option] if @config.has_key?(option)
      return @parent.get(option) if @parent
      nil
    end

    def get_or_default(option)
      get(option) || DEFAULTS[option].call
    end

    def method_missing(method_name, *args, &block)

      method_name_as_str = method_name.to_s
      option_str, suffix = method_name_as_str.match(/(\w+)([=\?])?$/).captures
      option = option_str.to_sym

      if args.any? || suffix == '='
        set(option, *args)
      elsif suffix == '?'
        val = get_or_default(option)
        # If its not a boolean value, question mark should not be used to query its value
        super(method_name, *args, &block) unless !!val === val
        val
      else
        get_or_default(option)
      end
    end
  end
end