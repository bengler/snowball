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

  it "serves js-files with the correct status code and content-type" do
    get "/assets/dummy.js"    
    last_response.status.should eq 200    
    last_response.content_type.should match /application\/javascript(;.+)?/
  end

  it "locates a js-file in the load path" do
    get "/assets/dummy.js"
    last_response.body.should match Regexp.escape('alert("Hello world")')
  end

  it "resolves a coffee-script entry file and serves it compiled" do
    get "/assets/some.js"
    last_response.status.should eq 200
    compiled = Regexp.escape("var func;\n\n  func = function(arg) {\n    return alert(\"Arg is \" + arg);\n  };\n\n}")
    last_response.body.should match compiled
  end

  it "includes transitive dependencies" do
    get "/assets/require.js"
    last_response.status.should eq 200
    last_response.body.should match Regexp.escape('console.log("Chunky bacon")')
  end


  it "Forwards errors to the browser by throwing them in the bundle" do
    get "/assets/will-fail.js"
    last_response.status.should eq 200

    last_response.body.should match /throw new Error\(\"Cannot find module\: \\"this\-module\-doesnt\-exist\\" from directory (.*) while processing file (.*)will\-fail\.js/
  end

  it "Also forwards parse/syntax errors" do
    get "/assets/syntax-error.js"
    last_response.status.should eq 200
    last_response.body.should match /throw new Error\(\"In (.*)syntax\-error\.coffee\, Parse error on line 1\: Unexpected \'\.\.\.\'\"/
  end

  it "Forwards parse/syntax errors even if the error occurs in a require()'d file" do
    get "/assets/require-error.js"
    last_response.status.should eq 200
    last_response.body.should match /throw new Error\(\"In (.*)syntax\-error\.coffee\, Parse error on line 1\: Unexpected \'\.\.\.\'\"/
  end

  it "Can specify a glob string of files that should be served raw" do
    get "/assets/meat/steak.js"
    last_response.status.should eq 200
    last_response.body.should match 'var steak = "raw"'
  end

end
