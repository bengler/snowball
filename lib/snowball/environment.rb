module Snowball
# Snowball Environment
# Possible options are:
#   root:         [optional] Sets the root path of the project. This is typically where package.json is located.
#                 If not specified, the current working directory will be used instead
#   source_path:  Defines the path to look for bundle files in (relative from root)
#   http_path:    Defines the http path to serve bundles from
#   extensions:   An array of extensions to use when resolving dependencies (.js and .json are always supported)
#   transforms:   Use these transform modules
#   jserr:        Forward errors as javascript throw statements. Useful during development to let bundle errors appear in 
#                 developer tools console instead of having a 500 error when loading javascript
#   debug:        Pass the debug flag to browserify. Will include source map (defaults to env['RACK_ENV'] == development)
#   raw:          If set to true, the files in the environment will be compiled/transformed, but not bundled. Useful if
#                 you have a source file with no require() statements or a file that is loaded dynamically after
#                 require() is defined
#
  class Environment
    DEFAULTS = {
        root: -> { nil },
        source_path: -> { nil },
        http_path: -> { nil },
        extensions: -> { [] },
        transforms: -> { [] },
        debug: -> { ENV['RACK_ENV'] == 'development' },
        externalize_source_map: -> { false },
        raw: -> { false },
        includes: -> { [] },
        noparse: -> { [] },
        jserr: -> { true },
        env: -> { {} },
        external: -> { false },
        cache: -> { false },
        fingerprint: -> { nil },
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

    def has?(option)
      return true if @config.has_key?(option)
      return @parent.has?(option) if @parent
      false
    end

    def get_or_default(option)
      raise InvalidOptionError, "No such configuration option #{option}" unless OPTIONS.include?(option)
      has?(option) ? get(option) : DEFAULTS[option].call
    end

    def respond_to?(method_name)
      OPTIONS.include?(method_name)
    end

    def method_missing(method_name, *args, &block)

      method_name_as_str = method_name.to_s
      option_str, suffix = method_name_as_str.match(/(\w+)([=\?])?$/).captures
      option = option_str.to_sym

      if block_given?
        set(option, block)
      elsif !args.empty? || suffix == '='
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