# frozen_string_literal: true

require 'csv'
require 'yaml'

require 'redis'
require 'connection_pool'

require './cache'

class BaseWorker
  attr_reader :worker_index, :threads_count, :requests_count, :redis_pool, :users_count, :test_time, :csv, :start_time

  STOP_SIGNALS = ['QUIT', 'INT', 'TERM'].freeze
  CSV_MUTEX = Mutex.new

  def initialize(csv_file_name, worker_index:, threads_count:, test_time:, users_count: 100)
    @worker_index = worker_index.to_i
    @threads_count = threads_count.to_i

    redis_config = YAML.load_file('redis.yml')
    @redis_pool = ConnectionPool.new(size: @threads_count * 1.5) { Redis.new(driver: :hiredis, **redis_config.to_h) }

    @users_count = users_count
    @test_time = test_time

    @csv = CSV.open(csv_file_name, 'a+')
    @csv_store = Hash.new(0)

    @start_time = Time.now.to_f
  end

  def run
    setup_stop_signal
    preconfigure

    puts "[#{worker_index}] Start"

    spawn_threads do |thread_index, counter|
      execute(worker_index, thread_index, counter)
    end

    total_time = Time.now.to_f - start_time
    total_count = @counters.values.sum
    total_csv_count = @csv_store.values.sum
    worker_status = total_csv_count == total_count ? 'DONE' : 'FAILED'

    puts "[#{worker_index}] #{worker_status}: #{total_time}. Processed #{total_count}. RPS: #{total_count / total_time}"

    @csv_store.each do |(sec, count)|
      CSV_MUTEX.synchronize do
        csv << [sec, count]
      end
    end

    Cache.new.write(worker_index, [total_count, total_count / total_time])
  end

  private

  def setup_stop_signal
    STOP_SIGNALS.each do |signal|
      trap(signal) do
        @stopped = true
      end
    end
  end

  def spawn_threads
    @threads = []
    end_time = Time.now.to_f + test_time

    @counters = Hash.new(0)

    threads_count.times.each do |thread_index|
      @threads << Thread.new do
        while true
          if @stopped
            Thread.current.exit
          end

          request_start_time = Time.now.to_f

          yield(thread_index, @counters[Thread.current])

          @csv_store[request_start_time.to_i - start_time.to_i] += 1
          @counters[Thread.current] += 1

          if end_time <= request_start_time
            @stopped = true
          end
        end
      end
    end

    @threads.each(&:join)
  end

  def preconfigure
    # nothing
  end

  def execute(worker_index, thread_index, counter)
    raise 'Not implemented'
  end
end
