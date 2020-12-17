require "ctes_in_my_pg/version"
#require 'byebug'

module CtesInMyPg
  class << self
    def supports_materialization_specifiers?
      return @supports_materialization_specifiers if defined?(@supports_materialization_specifiers)

      @supports_materialization_specifiers = ActiveRecord::Base.connection.postgresql_version >= 120000
    end
  end

  class SqlLiteral < Arel::Nodes::SqlLiteral
    def name
      self.to_s
    end
  end
end

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

      # Returns a new relation expressing WITH foo AS MATERIALIZED
      def materialized(*args)
        @scope.with_values += args
        @scope.materialized_values += args
        @scope
      end

      # Returns a new relation expressing WITH foo AS NOT MATERIALIZED
      def not_materialized(*args)
        @scope.with_values += args
        @scope.not_materialized_values += args
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

    def materialized_values
      @values[:materialized_values] || []
    end

    def materialized_values=(values)
      raise ImmutableRelation if @loaded
      @values[:materialized_values] = values
    end

    def not_materialized_values
      @values[:not_materialized_values] || []
    end

    def not_materialized_values=(values)
      raise ImmutableRelation if @loaded
      @values[:not_materialized_values] = values
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

    private

      def build_arel(aliases)
        arel = super(aliases)

        build_with(arel) if @values[:with]

        arel
      end

      def build_materialization(with_value)
        return unless CtesInMyPg.supports_materialization_specifiers?

        if materialized_values.include?(with_value)
          'MATERIALIZED'
        elsif not_materialized_values.include?(with_value)
          'NOT MATERIALIZED'
        end
      end

      def build_expression(with_value, expression)
        [build_materialization(with_value), "(#{expression})"].compact.join(' ')
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
                select = CtesInMyPg::SqlLiteral.new build_expression(with_value, expression)
              when ActiveRecord::Relation, Arel::SelectManager
                select = CtesInMyPg::SqlLiteral.new build_expression(with_value, expression.to_sql)
              end

              Arel::Nodes::As.new CtesInMyPg::SqlLiteral.new(PG::Connection.quote_ident(name.to_s)), select
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
