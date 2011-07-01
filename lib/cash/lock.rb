require 'socket'

module Cash
  class Lock
    class Error < RuntimeError; end

    INITIAL_WAIT = 2
    DEFAULT_RETRY = 8
    DEFAULT_EXPIRY = 30

    def initialize(cache)
      @cache = cache
    end

    def synchronize(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_RETRY, initial_wait = INITIAL_WAIT)
      if recursive_lock?(key)
        yield
      else
        acquire_lock(key, lock_expiry, retries, initial_wait)
        begin
          yield
        ensure
          release_lock(key)
        end
      end
    end

    def acquire_lock(key, lock_expiry = DEFAULT_EXPIRY, retries = DEFAULT_RETRY, initial_wait = INITIAL_WAIT)
      retries.times do |count|
        response = @cache.add("lock/#{key}", host_pid, lock_expiry)
        return if response == "STORED\r\n"
        return if recursive_lock?(key)
        exponential_sleep(count, initial_wait) unless count == retries - 1
      end
      debug_lock(key)
      raise Error, "Couldn't acquire memcache lock on #{@cache.get_server_for_key("lock/#{key}")}"
    end

    def release_lock(key)
      @cache.delete("lock/#{key}")
    end

    def exponential_sleep(count, initial_wait)
      sleep((2**count) / initial_wait)
    end

    private

    def recursive_lock?(key)
      @cache.get("lock/#{key}") == host_pid
    end

    def debug_lock(key)
      @cache.logger.warn("Cash::Lock[#{key}]: #{@cache.get("lock/#{key}")}") if @cache.respond_to?(:logger) && @cache.logger.respond_to?(:warn)
    rescue
      @cache.logger.warn("#{$!}") if @cache.respond_to?(:logger) && @cache.logger.respond_to?(:warn)
    end
    
    def host_pid
      "#{Socket.gethostname} #{Process.pid}"
    end
  end
end
