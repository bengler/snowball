require 'spec_helper'
require 'snowball/environment'
require 'snowball/file_resolver'

describe "Snowball::Bundle" do
  describe "Bundle" do
    let (:env) {
      Snowball::Environment.new do
        source_path "./spec/fixtures/js"
      end
    }
    it "should resolve a with an absolute path relative from the source dir" do
      resolver = Snowball::FileResolver.new(env)
      resolver.resolve("/other-source/steak.js").should eq "./spec/fixtures/js/other-source/steak.js"
    end
    it "should resolve a file with a relative path relative from the source dir" do
      resolver = Snowball::FileResolver.new(env)
      resolver.resolve("/other-source/steak.js").should eq "./spec/fixtures/js/other-source/steak.js"
    end
    it "should disallow path traversal" do
      resolver = Snowball::FileResolver.new(env)
      -> { resolver.resolve("../super-secret.js") }.should raise_error 
    end
    it "should resolve a registered extension to a js file" do
      env.extensions += [:jade]
      resolver = Snowball::FileResolver.new(env)
      resolver.resolve("/extensions/jade/hello.js").should eq "./spec/fixtures/js/extensions/jade/hello.jade" 
    end
    it "should disallow resolving files by their absolute_path" do
      absolute_path = File.absolute_path("./spec/fixtures/super-secret.js")
      File.exist?(absolute_path).should be_true
      resolver = Snowball::FileResolver.new(env)
      -> { resolver.resolve(absolute_path) }.should raise_error Errno::ENOENT
    end
    it "should fail with ConfigurationError if source path is not configured for environment" do
      env = Snowball::Environment.new
      resolver = Snowball::FileResolver.new(env)
      -> { resolver.resolve("/whatevs.js") }.should raise_error Snowball::ConfigurationError
    end
    it "should fail with ENOENT if the file doesn't exist" do
      resolver = Snowball::FileResolver.new(env)
      -> { resolver.resolve("/other-source/not-there.js") }.should raise_error Errno::ENOENT
    end
  end
end

