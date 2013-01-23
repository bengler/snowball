require 'open3'

unless File.exists?("./node_modules")
  # Run npm install to make sure we get all needed node modules
  puts "* Running npm install"
  Open3.popen3('npm install') do |stdin, stdout, stderr, wait_thr|
    fail "Error running 'npm install': #{stderr.read}" unless wait_thr.value.success?
  end
end

require 'bundler'
require 'simplecov'
require 'rack/test'
SimpleCov.add_filter "spec"
SimpleCov.start

Bundler.require