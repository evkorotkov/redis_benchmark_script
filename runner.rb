require 'csv'

require './cache'
require './leaderboard'
require './workload'
require './get'

def run
  cache = Cache.new
  processes_count = ARGV[0].to_i
  threads_count = ARGV[1].to_i
  test_time = ARGV[2].to_i
  test_type = ARGV[3]

  cache.flush

  current_time = Time.now.to_i
  csv_file_name = "output/#{test_type}_#{current_time}.csv"
  options = {
    threads_count: threads_count,
    test_time: test_time
  }

  processes_count.times do |worker_index|
    fork do
      case test_type
      when 'leaderboard'
        Leaderboard.new(csv_file_name, worker_index: worker_index, **options).run
      when 'workload'
        Workload.new(csv_file_name, worker_index: worker_index, **options).run
      when 'get'
        Get.new(csv_file_name, worker_index: worker_index, **options).run
      else
        puts 'invalid test name'
      end
    end
  end

  Process.waitall
ensure
  puts "TOTAL COUNT: #{cache.read_all.values.map(&:first).sum}"
  puts "TOTAL RPS: #{cache.read_all.values.map(&:last).sum}"
  puts "CURRENT_TIME: #{current_time}"
  puts "CSV_FILE: #{csv_file_name}"
end

run
