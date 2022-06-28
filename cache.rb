require 'pstore'

class Cache
  FILE_NAME = 'cache.pstore'

  attr_reader :store

  def initialize
    @store = PStore.new(FILE_NAME, true)
  end

  def write(key, value)
    store.transaction { store[key] = value }
  end

  def read(key)
    store.transaction(true) { store[key] }
  end

  def read_all
    store.transaction(true) do
      store.roots.each_with_object({}) do |key, memo|
        memo[key] = store[key]
      end
    end
  end

  def delete(key)
    store.transaction { store.delete(key) }
  end

  def flush
    store.transaction do
      store.roots.each do |key|
        store.delete(key)
      end
    end
  end
end
