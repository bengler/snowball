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

end
