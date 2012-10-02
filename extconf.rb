require 'mkmf'
require 'open3'

create_makefile("Dummy")

['npm install', 'npm shrinkwrap'].each do |cmd|
  puts "* Running #{cmd}"
  Open3.popen3(cmd) do |stdin, stdout, stderr, wait_thr|
    fail "Error running '#{cmd}': #{stderr.read}" unless wait_thr.value.success?
  end
end
