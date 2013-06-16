require "open3"

module Snowball
  EXECUTABLE = Pathname.new(__FILE__).join("../../../", "bin/roll.js").realpath
  class RollError < Exception; end

  class Roller
    def self.roll(file, environment)
      args = []

      args << environment.noparse.map { |node_module| "--noparse #{node_module}" }.join(" ")
      args << environment.includes.map { |node_module| "--require #{node_module}" }.join(" ")
      args << "--external" if environment.external?
      args << environment.transforms.map { |transform| "--transform #{transform}" }.join(" ")
      args << "--entry ./#{file}"
      args << '-d' if environment.debug?
      args << '--raw' if environment.raw?

      args += environment.env.map do |k,v|
        "--env #{k}=#{v}"
      end

      cmd = "node #{EXECUTABLE} #{args.join(" ")}"

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        source = stdout.read
        unless wait_thr.value.success?
          raise RollError.new "Got error while executing \"#{cmd}\" command: #{stderr.read}"
        end
        return source
      end
    end
  end
end
