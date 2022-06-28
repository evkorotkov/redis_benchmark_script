require './base_worker'

class Workload < BaseWorker
  def execute(worker_index, thread_index, counter)
    user_key = "user_#{worker_index}_#{thread_index}_#{counter % users_count}"

    redis_pool.with do |redis|
      redis.call('HGETALL', user_key)
      redis.call('EXPIRE', user_key, 900)

      redis.call('HSET', user_key, '1', '101')
      redis.call('HSET', user_key, '2', '201')
      redis.call('HSET', user_key, '3', '301')
      redis.call('HSET', user_key, '4', '1')
      redis.call('HSET', user_key, '5', '2')
      redis.call('HSET', user_key, '6', '4')
      redis.call('HSET', user_key, '7', '5')
      redis.call('HSET', user_key, '8', '6')
      redis.call('HSET', user_key, '9', 'some_value_1')

      redis.call('SADD', 'queues', 'changes')
      redis.call('LPUSH', 'queue:changes', "[{\"id\":\"1\",\"value\":\"101\"},{\"id\":\"2\",\"value\":\"201\"},{\"id\":\"3\",\"value\":\"301\"},{\"id\":\"4\",\"value\":\"1\"},{\"id\":\"5\",\"value\":\"2\"},{\"id\":\"6\",\"value\":\"4\"},{\"id\":\"7\",\"value\":\"5\"},{\"id\":\"8\",\"value\":\"6\"},{\"id\":\"9\",\"value\":\"some_value_1\"}]")
    end
  end
end
