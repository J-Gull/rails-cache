module Cash
  module Relation
    module CachedFinderMethods

      def where_with_cache(where_clause)          
debugger
        return where_without_cache(where_clause) if where_clause.keys.detect{|conditional_attr| @klass.indices.collect(&:attributes).flatten.include? conditional_attr.to_s}.blank?
        result = repository.get(cache_key(where_clause))

        if result.blank?
          result = where(where_clause)
          repository.add(cache_key(where_clause), result)
        else
          logger.debug "Cache Hits for #{cache_key(where_clause)}"
        end
      end

      def find_with_cache(match, attributes=nil, *args)
        debugger
        if attributes.blank? or attributes[:conditions].blank?
          if match == :all        #Message.find :all queries will go here
            self.send(match)
          else
            find_one_with_cache(match)
          end
        else
          conditions = attributes[:conditions]
          candidate_attributes = []
          conditional_attributes = conditions[0] if conditions.class == Array
          conditional_attributes.split(/and|or/i).each do |attr|
            candidate_attributes << attr.split(/in|\=/i).first
          end

          return find_by_attributes_without_cache(match, attributes, *args) if candidate_attributes.detect{|conditional_attr| @klass.indices.collect(&:attributes).flatten.include? conditional_attr}.blank?
          t_conditions = conditions.dup
          t_conditions[0].gsub!(/\=\?/, "")
          result = repository.get(cache_key(conditions.to_s))

          if result.blank?
            result = where(conditions).send(match)
            repository.add(cache_key(conditions.to_s), result)
          else
            logger.debug "Cache Hits for #{cache_key(conditions.to_s)}"
          end
        end
        
      end

      def find_by_attributes_with_cache(match, attributes, *args)
debugger
        conditions = attributes.inject({}) {|h, a| h[a] = args[attributes.index(a)]; h}
        return find_by_attributes_without_cache(match, attributes, *args) if conditions.keys.detect{|conditional_attr| @klass.indices.collect(&:attributes).flatten.include? conditional_attr}.blank?
        #return find_by_attributes_without_cache(match, attributes, *args) unless @klass.cacheable?
        #result = Query::Select.perform(self, conditions, nil).send(match.finder)
        result = repository.get(cache_key(conditions.to_s))
        
        if result.blank?
          result = where(conditions).send(match.finder)
          repository.add(cache_key(conditions.to_s), result)
        else
          logger.debug "Cache Hits for #{cache_key(conditions.to_s)}"
        end

        if match.bang? && result.blank?
          raise RecordNotFound, "Couldn't find #{@klass.name} with #{conditions.to_a.collect {|p| p.join(' = ')}.join(', ')}"
        else
          result
        end
      end

      def find_one_with_cache(id)
        return find_one_without_cache(id) unless @klass.cacheable?
        id = id.id if ActiveRecord::Base === id        
        record = @klass.get(id) do
          find_one_without_cache(id)
        end
        
        unless record
          conditions = arel.wheres.map { |x| x.value }.join(', ')
          conditions = " [WHERE #{conditions}]" if conditions.present?
          raise RecordNotFound, "Couldn't find #{@klass.name} with ID=#{id}#{conditions}"
        end

        record
      end
      
      def find_some_with_cache(ids)
        debugger
        return find_some_without_cache(ids) unless @klass.cacheable?
        result = @klass.get(ids) do
          #         puts "getting without cache"
          find_some_without_cache(ids)
        end
        
        result = ids.collect { |id| result[@klass.cache_key(id)] }.flatten.compact

        expected_size =
          if @limit_value && ids.size > @limit_value
          @limit_value
        else
          ids.size
        end

        # 11 ids with limit 3, offset 9 should give 2 results.
        if @offset_value && (ids.size - @offset_value < expected_size)
          expected_size = ids.size - @offset_value
        end

        if result.size == expected_size
          result
        else
          conditions = arel.wheres.map { |x| x.value }.join(', ')
          conditions = " [WHERE #{conditions}]" if conditions.present?

          error = "Couldn't find all #{@klass.name.pluralize} with IDs "
          error << "(#{ids.join(", ")})#{conditions} (found #{result.size} results, but was looking for #{expected_size})"
          raise RecordNotFound, error
        end
      end
    end
  end
end