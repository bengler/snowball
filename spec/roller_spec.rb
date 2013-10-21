require 'spec_helper'
require 'snowball/environment'
require 'snowball/file_resolver'

describe "Snowball::Roller" do
  describe "Roller" do
    let (:env) {
      Snowball::Environment.new do
        root "./spec/fixtures"
        source_path "./js"
        cache false
      end
    }
    let (:resolver) {
      Snowball::FileResolver.new(env)
    }

    describe "Basic" do
      it "should take an entry file and return the bundle code" do
        Snowball::Roller.roll(resolver.resolve("/bacon.js"), env)['code'].should include "exports.saySomething"
      end
    end
    describe "The noparse option" do
      it "should allow specifying node modules to not parse" do
        env.noparse = ['bloat']
        code = Snowball::Roller.roll(resolver.resolve("./noparse.js"), env)['code']
        code.should include 'var bloat = require("bloat")'
        code.should_not include 'alert("This is foo");'
      end
      it "should allow specifying single files to not parse" do
        env.noparse = ['./js/noparse.js']
        code = Snowball::Roller.roll(resolver.resolve("./requirenoparse.js"), env)['code']
        code.should include 'require("./noparse")'
        code.should_not include 'alert("This is foo");'
      end
    end

    describe "The raw option" do
      before do
        env.raw = true
      end
      it "should allow bundling files without using browserify" do        
        code = Snowball::Roller.roll(resolver.resolve("./raw.js"), env)['code']
        code.should eq 'console.log("A raw file, with no require() statements!");'
      end
      it "should transform source files using registered transforms" do
        env.extensions += [:coffee]
        env.transforms += [:coffeeify]
        code = Snowball::Roller.roll(resolver.resolve("./extensions/coffee-script/raw.coffee"), env)['code']
        code.should include 'if (typeof elvis !== "undefined" && elvis !== null)'
        code.should include 'alert("I knew it!")'
      end
    end

    describe "The jserr option" do
      it "if set to true it should roll successfully but with a throw statement in the code" do
        env.jserr true
        -> { Snowball::Roller.roll(resolver.resolve("./require-error.js"), env) }.should_not raise_error
        code = Snowball::Roller.roll(resolver.resolve("./require-error.js"), env)['code']
        code.should match /throw new Error\(.*ParseError.*\)/
      end
      it "if set to false it should raise a RollError whenever something goes wrong" do
        env.jserr false
        -> { Snowball::Roller.roll(resolver.resolve("./require-error.js"), env) }.should raise_error Snowball::RollError
      end
    end

    describe "Source maps" do
      before do
        env.debug = true
      end
      it "should inline the source map if debug is true" do
        code = Snowball::Roller.roll(resolver.resolve("/bacon.js"), env.for("/bacon.js"))['code']
        code.should match /\/\/(@|#)\s*sourceMappingURL=data:application\/json;base64/
      end
      it "should support externalizing the source map" do
        env.externalize_source_map = true
        result = Snowball::Roller.roll(resolver.resolve("/bacon.js"), env.for("/bacon.js"))
        result['code'].should_not match /\/\/(@|#)\s*sourceMappingURL=data:application\/json;base64/
        result['code'].should match /\/\/(@|#)\s*sourceMappingURL=bacon\.map/
        result['map'].should_not be_nil
      end
      it "should support specifying the url of source map" do
        env.externalize_source_map = true
        result = Snowball::Roller.roll(resolver.resolve("/bacon.js"), env.for("/bacon.js"), {source_map_url: "/some/path/bacon.map"})
        result['code'].should_not match /\/\/(@|#)\s*sourceMappingURL=data:application\/json;base64/
        result['code'].should match /\/\/(@|#)\s*sourceMappingURL=\/some\/path\/bacon\.map/
        result['map'].should_not be_nil
      end
    end
  end
end
