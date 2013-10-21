module Snowball
  class Cache
    def initialize(environment)
      @environment = environment
    end

    def etag_for(file)
      if (fingerprinter = @environment.get(:fingerprint)) && fingerprinter.respond_to?(:call)
        @environment.fingerprint.call(file)
      end
    end
  end
end