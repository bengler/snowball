require "open3"

module Snowball
  EXECUTABLE = Pathname.new(__FILE__).join("../../../", "bin/roll.js").realpath
  class BrowserifyError < Exception; end
  class Roller
    def initialize(entry, opts={})
      @ignores = %w(jsdom xmlhttprequest location navigator)
      @ignores.concat opts[:ignores] if opts[:ignores]
      @entry = entry
    end

    def roll
      ignore_args = @ignores.map { |i| "--ignore #{i}" }.join(" ")
      
      cmd = "node #{EXECUTABLE} #{ignore_args} -e #{@entry}"

      Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
        source = stdout.read
        unless (err = stderr.read).empty?
          raise BrowserifyError.new "Got error while executing \"#{cmd}\" command: #{err}"
        end
        return source
      end
    end
  end
end