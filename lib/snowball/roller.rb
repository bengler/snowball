require "open3"
require "json"
require 'ostruct'

module Snowball
  EXECUTABLE = Pathname.new(__FILE__).join("../../../", "bin/roll.js").realpath
  class RollError < Exception; end

  class Roller
    def self.roll(file, environment, opts={})
      start = Time.new

      if environment.raw? and not environment.browserify?
        return { 'code' => File.read(file) }
      end
      
      args = []

      args << environment.noparse.map { |node_module| "--noparse #{node_module}" }.join(" ")
      args << environment.includes.map { |node_module| "--require #{node_module}" }.join(" ")
      args << "--external" if environment.external?
      args << environment.transforms.map { |transform| "--transform #{transform}" }.join(" ")
      args << environment.extensions.map { |extension| "--extension .#{extension}" }.join(" ")
      args << '--debug' if environment.debug?
      args << '--jserr' if environment.jserr?
      args << '--browserify' if environment.browserify?
      if environment.externalize_source_map?
        args << '--externalize-source-map'
        source_map_url = opts[:source_map_url] || "#{File.basename(file, File.extname(file))}.map"
        args << "--externalize-source-map-url #{source_map_url}"
      end
      args << "--entry #{file}"

      cmd = "node #{EXECUTABLE} #{args.join(" ")}"

      opts = {}
      opts[:chdir] = environment.root if environment.root
      stdout, stderr, status = Open3.capture3(environment.env, cmd, opts)

      unless status.success?
        raise RollError.new "Got error while executing \"#{cmd}\" command: #{stderr}"
      end

      res = JSON.parse(stdout)
      Snowball.logger.info "Rolling took #{Time.now - start}ms"
      return res
    end
  end
end
