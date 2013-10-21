module Snowball
  class FileResolver
    def initialize(environment)
      @environment = environment
    end

    # Resolves a file relative to the environment's root+source path
    # Uses the configured extensions of the environment to search for source files 
    def resolve(file)
      raise Snowball::ConfigurationError.new("No source path configured for environment") unless @environment.source_path

      root = Pathname.new(@environment.root || '.')
      source_path = root.join(@environment.source_path)
      extensions = [:js, :json] + @environment.extensions

      file = ".#{file}" if Pathname(file).absolute?
      try_file = source_path.join(file)

      # Skip if file is not descendant of the current source path
      raise Errno::ENOENT.new(file) unless try_file.expand_path.to_path.start_with?(source_path.expand_path.to_path)

      extensions.each do |ext|
        try_file_ext = try_file.sub_ext(".#{ext}")
        return "./#{try_file_ext.relative_path_from(root)}" if try_file_ext.file?
      end
      raise Errno::ENOENT.new(file)
    end
  end
end