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
        @relation ||= ActiveRecord::Relation.new(self, arel_table)
        @relation.is_cached = true
        relation_without_cache
      end

      def without_cache(&block)
        with_scope(:find => {:readonly => true}, &block)
      end

      def find_every_without_cache(*args)
        find_without_cache(:all, *args)
      end
      
      def find_without_cache(*args)
        find(*args)
      end
      
      def calculate_without_cache(*args)
        calculate(*args)
      end
    end
  end
end
