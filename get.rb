require './base_worker'

class Get < BaseWorker
  TEST_KEY = 'test_key'.freeze
  TEST_VALUE = 'value'.freeze

  def preconfigure
    redis_pool.with do |redis|
      redis.call('SET', TEST_KEY, TEST_VALUE)
    end
  end

  def execute(worker_index, thread_index, counter)
    redis_pool.with do |redis|
      redis.call('GET', TEST_KEY)
    end
  end
end
