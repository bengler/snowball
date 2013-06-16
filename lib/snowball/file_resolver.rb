module Snowball
  class FileResolver
    def initialize(environment)
      @environment = environment
    end

    # Resolves a file relative to the environment's source path
    def resolve(file)
      source_path = Pathname.new(@environment.source_path)
      extensions = @environment.extensions

      try_file = source_path.join(file)

      # Skip if file is not descendant of the current source path
      raise Errno::ENOENT.new(try_file) unless try_file.expand_path.to_path.start_with?(source_path.expand_path.to_path)

      return try_file if try_file.file?
      extensions.each do |ext|
        try_ext = try_file.sub_ext(".#{ext}")
        return try_ext if try_ext.file?
      end
      raise Errno::ENOENT.new(try_file.to_s)
    end
  end
end