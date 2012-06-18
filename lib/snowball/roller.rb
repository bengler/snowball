module Snowball
  class Roller
    def initialize(entry, opts={})
      @ignores = %w(jsdom xmlhttprequest location navigator)
      @ignores.concat opts[:ignores] if opts[:ignores]
      @entry = entry
    end
    def roll
      ignore_args = @ignores.map {|i| "--ignore #{i}"}.join(" ")
      cmd = "node_modules/.bin/browserify #{ignore_args} -e #{@entry}"
      `#{cmd}`      
    end
  end
end