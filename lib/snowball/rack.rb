require 'snowball'
require 'rack'
require 'rack/mime'
require 'rack/utils'
require 'time'
require 'uri'

module Snowball
  # `Rack` provides a Rack compatible `call` that will serve a snowball environment
  # Largely based on the Sprockets::Server module.
  class Rack
    attr_accessor :environment

    def initialize(&blk)
      @environment = Snowball::Environment.new(&blk)
    end

    def cache
      @cache ||= ::Snowball::Cache.new(environment)
    end
    
    def resolver
      @resolver ||= ::Snowball::FileResolver.new(@environment)
    end
    
    # `call` implements the Rack 1.x specification which accepts an
    # `env` Hash and returns a three item tuple with the status code,
    # headers, and body.
    #
    # Mapping your environment at a url prefix will serve all entry_files
    # in the path.
    #     
    #     map "/js" do
    #       run Snowball::Rack.new {
    #         source_path "./javascript"
    #       }
    #     end
    #
    # A request for `"/js/foo/bar.js"` will return the contents of `"./javascript/foo/bar.js"`
    def call(env)

      # Mark session as "skipped" so no `Set-Cookie` header is set
      env['rack.session.options'] ||= {}
      env['rack.session.options'][:defer] = true
      env['rack.session.options'][:skip] = true

      # Extract the path from everything after the leading slash
      path = unescape(env['PATH_INFO'].to_s.sub(/^\//, ''))

      # URLs containing a `".."` are rejected to avoid path traversal
      if path.include?("..")
        return [ 403, { "Content-Type" => "text/plain", "Content-Length" => "9" }, [ "Forbidden" ] ]
      end

      # Strip fingerprint
      if (fingerprint = path_fingerprint(path))
        path = path.sub("#{fingerprint}", '')
      end

      # See if we are asking for a .map file
      if File.fnmatch("*.map", path)
        path = File.basename(path, '.map')
        return_map = true
      end

      # Look up the entry_file.
      entry_file = begin
        resolver.resolve(path)
      rescue Errno::ENOENT
        return [ 404, { "Content-Type" => "text/plain", "Content-Length" => "9", "X-Cascade" => "pass" }, [ "Not found" ] ]
      end

      # Check request headers `HTTP_IF_NONE_MATCH` against the entry_file digest
      if etag_match?(entry_file, env)
        # Return a 304 Not Modified
        return [304, {}, []]
      end

      source_map_url = "#{path}.map"
      # We got this far, now generate the bundle
      result = ::Snowball::Roller.roll(entry_file, environment.for(path), {source_map_url: source_map_url})
      if return_map
        [200, {"Content-Type" => "application/json"}, [result['map']]]
      else
        # Temporary fix for https://github.com/substack/node-browserify/issues/496
        result['code'].gsub!(/\n;$/, '')

        # Return a 200 with the entry_file contents
        [200, headers(env, entry_file, result['code']).merge("X-SourceMap" => source_map_url), [result['code']]]
      end
    end

    private
    
    def time(str)
      if @start_time
        puts "::> #{@str} (elapsed time: #{@time_elapsed.call}ms)"
        @start_time = nil
      end
      @str = str
      @start_time = start_time = Time.now.to_f
      @time_elapsed = lambda { ((Time.now.to_f - start_time) * 1000).to_i }
    end

    def content_type_of(path)
      ::Rack::Mime::MIME_TYPES[File.extname(path)]
    end

    def headers(env, entry_file, source)
      Hash.new.tap do |headers|
        # Set content type and length headers
        headers["Content-Type"]   = content_type_of(entry_file) || 'text/plain'
        headers["Content-Length"] = source.length.to_s

        # Set caching headers
        headers["Cache-Control"]  = "public"
        if environment.has?(:fingerprint)
          headers["ETag"] = etag(entry_file)
          headers["Last-Modified"]  = File.mtime(entry_file).httpdate
        end
        # If the request url contains a fingerprint, set a long
        # expires on the response
        if path_fingerprint(env["PATH_INFO"])
          headers["Cache-Control"] << ", max-age=31536000"
          # Otherwise set `must-revalidate` since the entry_file could be modified.
        else
          headers["Cache-Control"] << ", must-revalidate"
        end
      end
    end

    def map_file(path)
      path[/(\.map)$/, 1]
    end

    def path_fingerprint(path)
      path[/(!(.*);)/, 1]
    end

    # URI.unescape is deprecated on 1.9. We need to use URI::Parser
    # if its available.
    if defined? URI::DEFAULT_PARSER
      def unescape(str)
        str = URI::DEFAULT_PARSER.unescape(str)
        str.force_encoding(Encoding.default_internal) if Encoding.default_internal
        str
      end
    else
      def unescape(str)
        URI.unescape(str)
      end
    end

    def etag_match?(entry_file, env)
      env["HTTP_IF_NONE_MATCH"] == etag(entry_file)
    end

    # Helper to quote the entry_files digest for use as an ETag.
    def etag(entry_file)
      %("#{cache.etag_for(entry_file)}")
    end
  end
end