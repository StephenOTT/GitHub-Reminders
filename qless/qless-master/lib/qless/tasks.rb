# Encoding: utf-8

namespace :qless do
  task :setup # no-op; users should define their own setup

  desc 'Start a worker with env: QUEUES, JOB_RESERVER, REDIS_URL, INTERVAL'
  task oldwork: :setup do
 #    require 'qless/worker'
 #    # Qless::Worker.start

	# qless = Qless::Client.new(url: ENV['REDIS_URL'])
	# queues = %w[ testing ].map { |name| qless.queues[name] }
	# job_reserver = Qless::JobReservers::ShuffledRoundRobin.new(queues)
	# worker = Qless::Workers::ForkingWorker.new(queues).run
  end
end
