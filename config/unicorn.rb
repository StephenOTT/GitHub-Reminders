

if ENV["RACK_ENV"] == "development"
  worker_processes 3
else
  worker_processes 3
end

timeout 30
preload_app true