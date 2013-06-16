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
    it "should be instantiated with an environment" do
      resolver = Snowball::FileResolver.new(env)
      resolver.resolve("bacon.js").should eq "./spec/fixtures/js/bacon.js"
      resolver.resolve("/other-source/steak.js").should eq "./spec/fixtures/js/other-source/steak.js"
    end
  end
end

