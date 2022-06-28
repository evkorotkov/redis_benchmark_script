require './base_worker'

class Leaderboard < BaseWorker
  LEADERBOARD_KEY = :dfly_leaderboard
  SCORES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11].freeze

  def execute(worker_index, thread_index, counter)
    user_key = "user_#{worker_index}_#{thread_index}_#{counter % users_count}"

    redis_pool.with do |redis|
      redis.call('ZADD', LEADERBOARD_KEY, SCORES[counter % 11], user_key)
      redis.call('ZREVRANGE', LEADERBOARD_KEY, 0, 9)
    end
  end
end
