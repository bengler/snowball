require 'spec_helper'
require 'snowball/environment'

describe "Snowball::Environment" do
  describe "Configuration block" do
    it "can be instantiated with a configuration block that is instance_eval'd" do
      env = Snowball::Environment.new do
        source_path "js"
      end
      env.source_path.should eq 'js'
    end
    it "can be configured with by calling the environment instance itself" do
      env = Snowball::Environment.new
      env.source_path "js"
      env.source_path.should eq 'js'
    end

    it "should yield the instance to the configuration block" do
      env = Snowball::Environment.new do |env|
        env.source_path "js"
      end
      env.source_path.should eq 'js'
    end

    it "can be configured by setting configuration options using <env>.option=foo" do
      env = Snowball::Environment.new do |env|
        env.source_path = "js"
      end
      env.source_path.should eq 'js'
    end
  end

  describe "Environment api" do
    it "should allow querying boolean by ?" do
      env = Snowball::Environment.new do
        debug true
      end
      env.debug?.should be_true
      env.debug.should be_true
    end
    it "should raise an exception if querying for a boolean that is not really a boolean" do
      -> { Snowball::Environment.new.ignores? }.should raise_error NoMethodError
    end
  end

  describe "Specific configuration options" do
    it "should allow specifying bundle specific overrides" do
      env = Snowball::Environment.new do
        debug false
        match "*app.js" do
          debug true
        end
      end
      env.debug?.should be_false
      env.for("app.js").debug?.should be_true
    end
    it "should raise exception if attempting to define more than one level deep bundles" do
      env = Snowball::Environment.new
      bundle = env.match "some/path/"
      -> { bundle.match "some/path/" }.should raise_error NoMethodError, /Can only specify bundles in toplevel environments/
    end
  end
end
