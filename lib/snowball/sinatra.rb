require "snowball/file_resolver"
require "snowball/roller"
require 'pathname'

module Sinatra
  module Snowball
    def self.registered(app)
      app.helpers(Sinatra::Snowball::Helpers)
    end

    def snowball(&block)
      env = ::Snowball::Environment.new(&block)
      self.set :snowball, env

      self.get "#{env.http_path}/*" do |file|
        resolver = ::Snowball::FileResolver.new(env)
        begin
          entryfile = resolver.resolve(file)
        rescue Errno::ENOENT => e
          halt 404, "File #{file} not found: #{e}"
        end

        if File.extname(file) != '.js' or env.source?
          send_file file
        else
          content_type :js
          [200, ::Snowball::Roller.roll(entryfile, env.for(file))]
        end
      end
    end

    module Helpers
      def javascript_path(file)
        "#{self.settings.snowball.http_path}/#{file}.js"
      end

      def javascript_tag(file, opts={})
        "<script src=\"#{javascript_path(file)}\"#{' async' if opts[:async]}></script>"
      end
    end
  end
end