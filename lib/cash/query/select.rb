module Cash
  module Query
    class Select < Abstract
      delegate :find_without_cache, :to => :@active_record

      protected
      def miss(_, miss_options)
        find_without_cache(miss_options)
      end

      def uncacheable
        find_without_cache(@options1)
      end
    end
  end
end
