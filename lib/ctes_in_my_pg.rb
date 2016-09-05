require "ctes_in_my_pg/version"
#require 'byebug'

module ActiveRecord
  class Relation
    class Merger # :nodoc:
      def normal_values
        NORMAL_VALUES + [:with]
      end
    end
  end
end

module ActiveRecord::Querying
  delegate :with, to: :all
end

module ActiveRecord
  class Relation
    # WithChain objects act as placeholder for queries in which #with does not have any parameter.
    # In this case, #with must be chained with #recursive to return a new relation.
    class WithChain
      def initialize(scope)
        @scope = scope
      end

      # Returns a new relation expressing WITH RECURSIVE
      def recursive(*args)
        @scope.with_values += args
        @scope.recursive_value = true
        @scope
      end
    end

    def with_values
      @values[:with] || []
    end

    def with_values=(values)
      raise ImmutableRelation if @loaded
      @values[:with] = values
    end

    def recursive_value=(value)
      raise ImmutableRelation if @loaded
      @values[:recursive] = value
    end

    def recursive_value
      @values[:recursive]
    end

    def with(opts = :chain, *rest)
      if opts == :chain
        WithChain.new(spawn)
      elsif opts.blank?
        self
      else
        spawn.with!(opts, *rest)
      end
    end

    def with!(opts = :chain, *rest) # :nodoc:
      if opts == :chain
        WithChain.new(self)
      else
        self.with_values += [opts] + rest
        self
      end

    end

    def build_arel
      arel = super()

      build_with(arel) if @values[:with]

      arel
    end

    def build_with(arel)
      with_statements = with_values.flat_map do |with_value|
        case with_value
        when String
          with_value
        when Hash
          with_value.map  do |name, expression|
            case expression
            when String
              select = Arel::Nodes::SqlLiteral.new "(#{expression})"
            when ActiveRecord::Relation, Arel::SelectManager
              select = Arel::Nodes::SqlLiteral.new "(#{expression.to_sql})"
            end
            Arel::Nodes::As.new Arel::Nodes::SqlLiteral.new("\"#{name.to_s}\""), select
          end
        when Arel::Nodes::As
          with_value
        end
      end

      unless with_statements.empty?
        if recursive_value
          arel.with :recursive, with_statements
        else
          arel.with with_statements
        end
      end
    end

    #alias_method_chain :build_arel, :extensions
    # use method overriding, not alias_method_chain, as per Yehuda:
    # http://yehudakatz.com/2009/03/06/alias_method_chain-in-models/
  end
end
