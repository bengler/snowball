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

  describe "Environment configuration api" do
    it "should allow querying boolean by ?" do
      env = Snowball::Environment.new do
        debug true
        match "child.js" do
          debug false
        end
      end
      env.debug?.should be_true
      env.debug.should be_true
      env.for("child.js").debug?.should be_false
    end

    it "should return configuration option value from parent environments if it is not overridden" do
      env = Snowball::Environment.new do
        debug true        
        match "child.js" do
        end
      end
      env.debug?.should be_true
      env.for("child.js").debug?.should be_true
    end

    it "should return parent environment if no environment matches file" do
      env = Snowball::Environment.new
      env.for("child.js").should eq env
    end

    it "should raise an exception if querying for a boolean that is not really a boolean" do
      -> { Snowball::Environment.new.noparse? }.should raise_error NoMethodError
    end

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

    it "should raise exception if attempting to override source path for child environment" do
      child = Snowball::Environment.new.match("app")
      -> { child.source_path = "/whatevs" }.should raise_error Snowball::InvalidOptionError
    end

    it "should raise exception if attempting to override http path for child environment" do
      child = Snowball::Environment.new.match("app")
      -> { child.http_path = "/whatevs" }.should raise_error Snowball::InvalidOptionError
    end

    it "should raise exception if attempting to define more than one level deep bundles" do
      env = Snowball::Environment.new
      bundle = env.match "some/path/"
      -> { bundle.match "some/path/" }.should raise_error NoMethodError, /Can only specify bundles in toplevel environments/
    end
  end
  describe "Current configuration options and their defaults" do
    let (:env) { Snowball::Environment.new }

    it "should set/get source_path" do
      env.source_path.should be_nil
      env.source_path = "./foo/js"
      env.source_path.should eq "./foo/js"
    end

    it "should set/get http_path" do
      env.http_path.should be_nil
      env.http_path = "/js"
      env.http_path.should eq "/js"
    end

    it "should set/get extensions" do
      env.extensions.should eq []
      env.extensions += [:coffee]
      env.extensions += [:ls]
      env.extensions.should eq [:coffee, :ls]
    end
    
    it "should set/get transforms" do
      env.transforms.should eq []
      env.transforms = [:coffeeify, :liveify]
      env.transforms.should eq [:coffeeify, :liveify]
    end
    
    it "should set/get debug" do
      env.debug?.should be_false # because RACK_ENV == test
      env.debug = true
      env.debug?.should be_true
    end
    
    it "should set/get externalize_source_map" do
      env.externalize_source_map?.should be_false
      env.externalize_source_map true
      env.externalize_source_map?.should be_true
    end
    
    it "should set/get raw" do
      env.raw?.should be_false
      env.raw = true
      env.raw?.should be_true
    end

    it "should set/get includes" do
      env.includes.should eq []
      env.includes += [:jquery]
      env.includes.should eq [:jquery]
    end

    it "should set/get noparse" do
      env.noparse.should eq []
      env.noparse [:jquery]
      env.noparse << :threejs
      env.noparse += [:angular]
      env.noparse.should eq [:jquery, :threejs, :angular]
    end

    it "should set/get environment variables" do
      env.env.should eq ({})
      env.env :NODE_ENV => "development"
      env.env[:FOO] = "bar"
      env.env[:NODE_ENV].should eq 'development'
      env.env[:FOO].should eq 'bar'
    end

    it "should set/get external" do
      env.external?.should be_false
      env.external = true
      env.external?.should be_true
    end

    it "should set/get cache flag" do
      env.cache?.should be_false
      env.cache = true
      env.cache?.should be_true
    end

    it "should set/get fingerprint lambda" do
      env.fingerprint.should be_nil
      env.fingerprint do
        "foo"
      end
      env.fingerprint.call.should eq "foo"
    end
  end
end
