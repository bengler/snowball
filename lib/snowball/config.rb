module Snowball
  class Config
    def self.read(file)
      environment = Snowball::Environment.new
      environment.instance_eval(File.read(file))
      environment
    end
  end
end
