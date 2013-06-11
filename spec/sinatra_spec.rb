require 'spec_helper'
require 'json'
require 'sinatra'
require 'snowball/sinatra'

require 'fixtures/snowball_app'

describe "SnowballApp" do
  include Rack::Test::Methods

  def app
    SnowballApp
  end

  describe "endpoints" do
    it "serves js-files with the correct status code and content-type" do
      get "/js/dummy.js"
      last_response.status.should eq 200
      last_response.content_type.should match /application\/javascript(;.+)?/
    end

    it "locates a js-file in the load path" do
      get "/js/dummy.js"
      last_response.body.should match Regexp.escape('alert("Hello world")')
    end

    it "serves the javascript entry raw (not browserified) it matches the configured glob strings" do
      get "/js/raw.js"
      last_response.status.should eq 200
      last_response.body.should match Regexp.escape('console.log("That is awesome!");')
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

    it "can specify a glob string of files that should be served raw" do
      get "/js/steak.js"
      last_response.status.should eq 200
      last_response.body.should match 'var steak = "raw"'
    end

    describe "extensions" do
      describe "coffee-script support" do
        it "resolves a coffee-script entry file and serves it compiled" do
          get "/js/extensions/coffee-script/some.js"
          last_response.status.should eq 200
          compiled = Regexp.escape("func = function(arg) { return alert(\"Arg is \" + arg); }; }".gsub(/\s+/, ""))
          last_response.body.gsub(/\s+/, "").should match compiled
        end

        it "serves the coffee-script file as source if requested with .coffee as extension" do
          get "/js/extensions/coffee-script/require.coffee"
          last_response.status.should eq 200
          last_response.body.should match Regexp.escape("test = ->")
        end

        it "serves the coffee-script entry raw (compiled, but not browserified) it matches the configured glob strings" do
          get "/js/extensions/coffee-script/raw.js"
          last_response.status.should eq 200
          last_response.body.should match Regexp.escape('alert("I knew it!");')
        end
      end
    end
  end

  describe "sinatra helpers" do
    it "inserts a <script tag into the template" do
      get "/javascript_tag"
      last_response.body.should include '<script src="/js/some.js"></script>'
    end
    it "inserts a <script tag into the template" do
      get "/javascript_tag_async"
      last_response.body.should include '<script src="/js/pastry/tart.js" async></script>'
    end
    it "inserts a <script tag into the template" do
      get "/javascript_path"
      last_response.body.should include "<script src='/js/food/steak.js'></script>"
    end
  end
end
