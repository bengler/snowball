require "open3"

module Snowball
  EXECUTABLE = Pathname.new(__FILE__).join("../../../", "bin/roll.js").realpath
  class RollError < Exception; end

  class Roller
    def self.roll(entry, opts)
      args = []

      ignores = opts.ignores.dup
      ignores.unshift *%w(jsdom xmlhttprequest location navigator)
      ignores.uniq!

      args << ignores.map { |node_module| "--ignore #{node_module}" }.join(" ")
      args << opts.includes.map { |node_module| "--require #{node_module}" }.join(" ")
      args << "--prelude #{!!opts.prelude}"
      args << "--entry #{entry}"

      args += (opts.env || {}).map do |k,v|
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