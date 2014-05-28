

if ENV["RACK_ENV"] == "development"
  worker_processes 3
else
  worker_processes 3
end

timeout 30
preload_app true


before_fork do |server, worker|
  # ...

  # If you are using Redis but not Resque, change this
  if defined?(Resque)
    Qless.redis.quit
    # Rails.logger.info('Disconnected from Redis')
  end
end

after_fork do |server, worker|
  # ...

  # If you are using Redis but not Resque, change this
  if defined?(Resque)
    Qless.redis = ENV['REDIS_URI']
    # Rails.logger.info('Connected to Redis')
  end
end