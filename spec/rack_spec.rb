require 'spec_helper'
require 'json'
require 'sinatra'
require 'snowball/rack'

describe "SnowballApp" do
  include Rack::Test::Methods

  let (:app) {
    Snowball::Rack.new(&conf)
  }
  describe "source paths and serve path" do
    let (:conf) {
      proc {
        source_path "./spec/fixtures"
        serve_path "/js"
      }
    }

    it "serves js-files with the correct status code and content-type" do
      get "/js/dummy.js"
      last_response.status.should eq 200
      last_response.content_type.should match /application\/javascript(;.+)?/
    end

    it "locates a js-file in the load path" do
      get "/js/dummy.js"
      last_response.body.should match Regexp.escape('alert("Hello world")')
    end

    it "serves the javascript entry raw (not browserified) if it matches the configured glob strings" do
      get "/js/raw.js"
      last_response.status.should eq 200
      last_response.body.should match Regexp.escape('console.log("A raw file, with no require() statements!");')
    end

    it "includes transitive dependencies" do
      get "/js/require.js"
      last_response.status.should eq 200
      last_response.body.should match Regexp.escape('console.log("Chunky bacon")')
    end

    it "returns 404 for files not found" do
      get "/js/thisdoesntexists.js"
      last_response.status.should eq 404
    end

    it "also forwards errors" do
      get "/js/syntax-error.js"
      last_response.status.should eq 200
      last_response.body.should match /throw new Error\(".*"\)/m
    end

    it "forwards parse/syntax errors even if the error occurs in a require()'d file" do
      get "/js/require-error.js"
      last_response.status.should eq 200
      last_response.body.should match /throw new Error\(".*"\)/m
    end
  end

  describe "extensions" do
    let (:conf) {
      proc {
        source_path "./spec/fixtures"
        serve_path "/js"
        extensions [:coffee]
        transforms [:coffeeify]
        match "*/coffee-script/raw.coffee" do
          browserify off
          raw on
        end
      }
    }
    describe "coffee-script support" do
      it "resolves a coffee-script entry file and serves it compiled" do
        get "/js/extensions/coffee-script/some.js"
        last_response.status.should eq 200
        compiled = Regexp.escape("func = function(arg) { return alert(\"Arg is \" + arg); }; }".gsub(/\s+/, ""))
        last_response.body.gsub(/\s+/, "").should match compiled
      end

      it "serves the coffee-script file as source if it matches a configured pattern" do
        get "/js/extensions/coffee-script/raw.coffee"
        last_response.status.should eq 200
        last_response.body.should match Regexp.escape('alert "I knew it!" if elvis?')
      end

      it "serves the coffee-script entry raw (compiled, but not browserified) it matches the configured glob strings" do
        get "/js/extensions/coffee-script/raw.js"
        last_response.status.should eq 200
        last_response.body.should include 'if (typeof elvis !== "undefined" && elvis !== null) {'
        last_response.body.should include 'alert("I knew it!");'
        last_response.body.should include '}'
      end
    end
  end
end
