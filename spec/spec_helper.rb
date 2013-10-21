require 'open3'

# Run npm install to make sure we get all needed node modules
['./', './spec/fixtures/'].each do |dir|
  puts "* Running npm install in #{dir}"
  Open3.popen3('npm install', {chdir: dir}) do |stdin, stdout, stderr, wait_thr|
    fail "Error running 'npm install' in #{dir}: #{stderr.read}" unless wait_thr.value.success?
  end
end

require 'bundler'
require 'simplecov'
require 'rack/test'
SimpleCov.add_filter "spec"
SimpleCov.start

Bundler.require