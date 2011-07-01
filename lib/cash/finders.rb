module Cash
  module Finders
    def self.included(active_record_class)
      active_record_class.class_eval do
        extend ClassMethods
      end
    end

    module ClassMethods
      def self.extended(active_record_class)
        class << active_record_class
          alias_method_chain :relation, :cache
        end
      end

      def relation_with_cache #:nodoc:
	#puts "getting relation with cache: #{caller(0).join("\n")}"
        @relation ||= ActiveRecord::Relation.new(self, arel_table)
        @relation.is_cached = true
        relation_without_cache
      end

      def without_cache(&block)
	#puts "getting without cache: #{caller(0).join("\n")}"
        with_scope(:find => {:readonly => true}, &block)
      end

      def find_every_without_cache(*args)
	#puts "getting without cache: #{caller(0).join("\n")}"
        find_without_cache(:all, *args)
      end
      
      def find_without_cache(*args)
	#puts "getting without cache: #{caller(0).join("\n")}"
        find(*args)
      end
      
      def calculate_without_cache(*args)
	#puts "getting without cache: #{caller(0).join("\n")}"
        calculate(*args)
      end
    end
  end
end
