module Cash
  module Accessor
    def self.included(a_module)
      a_module.module_eval do
        extend ClassMethods
        include InstanceMethods
      end
    end

    module ClassMethods
      def cache_log(message)
        ActiveRecord::Base.logger.debug("  CACHE #{message}") if ActiveRecord::Base.logger
      end
      
      def fetch(keys, options = {}, &block)
        case keys
        when Array
          return {} if keys.empty?
          
          keys = keys.collect { |key| cache_key(key) }
          cache_log("GET_MULTI   #{keys.inspect}")
          hits = repository.get_multi(*keys)
          if (missed_keys = keys - hits.keys).any?
            missed_values = block.call(missed_keys)
            hits.merge!(missed_keys.zip(Array(missed_values)).to_hash_without_nils)
          end
          hits
        else
          cache_log("GET   #{cache_key(keys).inspect}")
          repository.get(cache_key(keys), options[:raw]) || (block ? block.call : nil)
        end
      end

      def get(keys, options = {}, &block)
        case keys
        when Array
          fetch(keys, options, &block)
        else
          fetch(keys, options) do
            if block_given?
              add(keys, result = yield(keys), options)
              result
            end
          end
        end
      end

      def add(key, value, options = {})
        cache_log("ADD   #{cache_key(key)} = #{value.inspect}   (#{options[:ttl] || cache_config.ttl}, #{options[:raw]})")
#PATCH:SIMOBO        if repository.add(cache_key(key), value, options[:ttl] || cache_config.ttl, options[:raw]) == "NOT_STORED\r\n"
        if repository.add(cache_key(key), value, options[:ttl] || cache_config.ttl, options) == "NOT_STORED\r\n"
          yield if block_given?
        end
      end

      def set(key, value, options = {})
        cache_log("SET   #{cache_key(key)} = #{value.inspect}   (#{options[:ttl] || cache_config.ttl}, #{options[:raw]})")
#PATCH:SIMOBO        repository.set(cache_key(key), value, options[:ttl] || cache_config.ttl, options[:raw])
        repository.set(cache_key(key), value, options[:ttl] || cache_config.ttl, options)
      end

      def incr(key, delta = 1, ttl = nil)
        ttl ||= cache_config.ttl
        repository.incr(cache_key = cache_key(key), delta) || begin
#PATCH:SIMOBO          repository.add(cache_key, (result = yield).to_s, ttl, true) { repository.incr(cache_key) }
          repository.add(cache_key, (result = yield).to_s, ttl, {:raw => true}) { repository.incr(cache_key) }
          result
        end
      end

      def decr(key, delta = 1, ttl = nil)
        ttl ||= cache_config.ttl
        repository.decr(cache_key = cache_key(key), delta) || begin
#PATCH:SIMOBO          repository.add(cache_key, (result = yield).to_s, ttl, true) { repository.decr(cache_key) }
          repository.add(cache_key, (result = yield).to_s, ttl, {:raw => true}) { repository.decr(cache_key) }
          result
        end
      end

      def expire(key)
        repository.delete(cache_key(key))
      end

      def cache_key(key)
        "#{name}:#{cache_config.version}/#{key.to_s.gsub(' ', '+')}"
      end
    end

    module InstanceMethods
      def expire
        self.class.expire(id)
      end
    end
  end
end
