require "snowball/roller"

module Sinatra
  module Snowball

    # Resolves a file relative to the load path
    def self.resolve_file(settings, file)
      load_paths = settings.load_paths
      extensions = %w(js coffee) # todo: make configurable?
      load_paths.each do |path|
        f = File.join(path, file)
        return f if File.exists?(f)
        extensions.each do |ext|
          f = File.join(path, "#{File.basename(file, File.extname(file))}.#{ext}")
          return f if File.exists?(f)
        end
      end
      raise "File #{file} not found (Load paths: #{load_paths.inspect})"
    end

    class Config
      attr_accessor :serve_path, :load_paths, :ignore

      def set_serve_path(path)
        @serve_path = path
      end

      def set_ignore(globstr)
        @ignore = globstr
      end

      def add_load_path(path)
        @load_paths ||= []
        @load_paths << path
      end
      
      def digest_file(&blk)
        
      end
    end

    def self.registered(app)
      app.helpers(Sinatra::Snowball::Helpers)
    end

    def snowball(&block)
      config = Config.new
      config.send(:instance_eval, &block)
      self.set :snowball, config
      self.get "#{config.serve_path}/*" do |bundle|
        content_type :js
        entryfile = Snowball.resolve_file config, bundle

        if config.ignore && File.fnmatch(config.ignore, entryfile)
          [200, File.read(entryfile)]
        else
          [200, ::Snowball::Roller.new(entryfile).roll]
        end
      end
    end

    module Helpers
      def javascript_path(file)
        "#{self.settings.snowball.serve_path}/#{file}.js"
      end
      def javascript_tag(file, opts={})
        "<script src=\"#{javascript_path(file)}\"#{' async' if opts[:async]}></script>"
      end
    end
  end
end