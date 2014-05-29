
worker_processes 3
timeout 30


before_fork do |server, worker|
  spawn("bundle exec rake " + "qless:work")
end