dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../lib"

require File.join(dir, '../config/environment')
require 'spec'
require 'pp'
require 'cache_money'
require 'memcached'
require 'memcache'
require 'ruby-debug'

Spec::Runner.configure do |config|
  config.after :suite do
    IO.popen("kill #{$memcached_pid}")
  end
  
  config.mock_with :rr
  config.before :suite do
    load File.join(dir, "../db/schema.rb")

    IO.popen('memcached -d -l 127.0.0.1 -p 11212')
    IO.popen('ps -ef | grep memcached | grep 11212') { |f| $memcached_pid = f.gets.split[1].to_i }
    p $memcached_pid

    config = { 'ttl'       => 604800,
               'namespace' => 'cache',
               'sessions'  => false,
               'debug'     => true,
               'servers'   => '127.0.0.1:11212'
    }
    $memcache = MemCache.new(config["servers"].gsub(' ', '').split(','), config)
    $lock = Cash::Lock.new($memcache)
    
    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.logger.level = Logger::DEBUG
  end

  config.before :each do
    $memcache.flush_all
    Story.delete_all
    Character.delete_all
  end

  config.before :suite do
    ActiveRecord::Base.class_eval do
      is_cached :repository => Cash::Transactional.new($memcache, $lock)
    end

    Character = Class.new(ActiveRecord::Base) unless defined?(Character)
    unless defined?(Story)
      Story = Class.new(ActiveRecord::Base)
      Story.has_many :characters

      Story.class_eval do
        index :title
        index [:id, :title]
        index :published
      end
    end

    unless defined?(Short)
      Short = Class.new(Story)
      Short.class_eval do
        index :subtitle, :order_column => 'title'
      end
    end

    Epic = Class.new(Story) unless defined?(Epic)
    Oral = Class.new(Epic)  unless defined?(Oral)

    Character.class_eval do
      index [:name, :story_id]
      index [:id, :story_id]
      index [:id, :name, :story_id]
    end

    Oral.class_eval do
      index :subtitle
    end
  end
end
