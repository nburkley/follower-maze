desc "Run the event notification server"
task :run_server do
  ruby "bin/run_server.rb"
end

task :run_server_in_thread do
  Thread.new do
    ruby "bin/run_server.rb"
  end
end

desc "Run the server and the provided test suite"
task :run_test_suite => :run_server_in_thread do
  sh "bin/followermaze.sh"
end

task :default  => :run_server

