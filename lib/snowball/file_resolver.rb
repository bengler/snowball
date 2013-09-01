module Snowball
  class FileResolver
    def initialize(environment)
      @environment = environment
    end

    # Resolves a file relative to the environment's source path
    # Uses the configured extensions of the environment to search for source files 
    def resolve(file)
      source_path = Pathname.new(@environment.source_path)
      extensions = [:js, :json] + @environment.extensions

      file = "./#{file}" if Pathname(file).absolute?
      try_file = source_path.join(file)

      # Skip if file is not descendant of the current source path
      raise Errno::ENOENT.new(try_file.to_path) unless try_file.expand_path.to_path.start_with?(source_path.expand_path.to_path)

      extensions.each do |ext|
        try_file_ext = try_file.sub_ext(".#{ext}")
        return try_file_ext.to_path if try_file_ext.file?
      end
      raise Errno::ENOENT.new(try_file.to_path)
    end
  end
end