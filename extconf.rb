require 'mkmf'
require 'open3'

create_makefile("Dummy")

puts "* Running npm install"
Open3.popen3('npm install') do |stdin, stdout, stderr, wait_thr|
  fail "Error running 'npm install': #{stderr.read}" unless wait_thr.value.success?
end