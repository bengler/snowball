require 'bundler'
require 'simplecov'
require 'rack/test'
SimpleCov.add_filter "spec"
SimpleCov.start

Bundler.require