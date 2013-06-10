require "snowball/roller"
require 'pathname'

module Sinatra
  module Snowball
    # Resolves a file relative to the source path
    def self.resolve_file(config, file)
      source_paths = config[:source_paths]
      extensions = config[:extensions]

      source_paths.each do |source_path|
        try_file = File.expand_path(File.join(source_path, file))

        # Skip if file is not descendant of the current source path
        next unless try_file =~ /^#{source_path}/

        return try_file if File.exists?(try_file)
        extensions.each do |ext|
          try_file = File.join(source_path, File.dirname(file), "#{File.basename(file, File.extname(file))}.#{ext}")
          return try_file if File.exists?(try_file)
        end
      end
      raise Errno::ENOENT.new(file)
    end

    def self.registered(app)
      app.helpers(Sinatra::Snowball::Helpers)
    end

    def snowball(&block)
      config = {}
      builder = ::Snowball::Config::Builder.new(config)
      builder.send(:instance_eval, &block)
      self.set :snowball, config
      self.get "#{config[:http_path]}/*" do |bundle|
        begin
          entryfile = Pathname.new(Snowball.resolve_file(config, bundle)).relative_path_from(Pathname.pwd)
        rescue Errno::ENOENT => e
          halt 404, "File #{bundle} not found"
        end

        if File.extname(bundle) != '.js' or config[:source].any? { |glob_str| File.fnmatch(glob_str, entryfile) }
          send_file entryfile
        else
          raw = config[:raw].any? { |glob_str| File.fnmatch(glob_str, bundle) }
          content_type :js
          [200, ::Snowball::Roller.roll(*[entryfile, config.merge({:raw => raw})].compact)]
        end
      end
    end

    module Helpers
      def javascript_path(file)
        "#{self.settings.snowball[:http_path]}/#{file}.js"
      end

      def javascript_tag(file, opts={})
        "<script src=\"#{javascript_path(file)}\"#{' async' if opts[:async]}></script>"
      end
    end
  end
end