## A real configuration ##

Here's a real config from http://brighterplanet.com. Note that WE USE LIBMEMCACHED with Evan Weaver's gem (so does Twitter).

For `config/preinitializer.rb`

    MEMCACHED_SERVERS = [ 'server1:11211', 'server2:11211', 'server3:11211' ]

For `config/environment.rb`

    config.gem 'memcached', :version => '0.17.3'
    config.cache_store = :mem_cache_store, MEMCACHED_SERVERS

For `config/initializers/cache_money.rb`

    require 'cache_money'

    # Compatibility shim for memcached gem (0.17.3 at time of writing)
    class Memcached
      class Rails < ::Memcached
        def get_multi(keys, raw=false)
          hits = get(keys, !raw)
          case hits
          when NilClass
            {}
          when String
            { keys => raw ? hits : Marshal.load(hits) }
          when Array
            hits.map! { |i| Marshal.load(i) } unless raw
            keys.zip(hits).to_hash_without_nils
          when Hash
            hits = hits.inject({}) { |memo, ary| k, v = ary; memo[k] = Marshal.load(v); memo } unless raw
            hits
          end
        end
      end
    end

    # Compatibility shim so that we can use the same memcached client for both Rails.cache and cache-money
    module Cash
      class Local
        def get_multi(*args)
          if args.first.is_a?(Array)          # [1,2,3], true
            @remote_cache.get_multi *args
          else                                # 1, 2, 3
            @remote_cache.get_multi args
          end
        end
    
        def delete(key, *options)
          @remote_cache.delete(key)
        end
      end
    end

    $memcache = Memcached::Rails.new MEMCACHED_SERVERS, :timeout => 2, :binary_protocol => true

    $local = Cash::Local.new $memcache
    $lock = Cash::Lock.new $memcache
    $cache = Cash::Transactional.new $local, $lock

    # NOTE: replacing the default memcache-client instance. YMMV
    Rails.cache.instance_variable_set :@data, $cache
    Rails.cache.silence!

    class ActiveRecord::Base
      is_cached :repository => $cache
    end

    # Make cache-money work with namespaced models
    ActiveRecord::Base.cache_config.inherit Delayed::Job
    # Make cache-money work with ActiveRecord models with self.abstract_class = true
    ActiveRecord::Base.cache_config.inherit Emitter

Hope that helps.
