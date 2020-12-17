require 'test_helper'

describe 'Common Table Expression queries' do
  describe '.with(common_table_expression_hash)' do
    it 'generates an expression with the CTE' do
      query = Person.with(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
      _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
    end

    it 'generates an expression with multiple CTEs' do
      query = Person.with(lucky_number_seven: Person.where(lucky_number: 7), lucky_number_three: Person.where(lucky_number: 3)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id').joins('JOIN lucky_number_three ON lucky_number_three.id = people.id')
      _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "lucky_number_three" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 3\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id JOIN lucky_number_three ON lucky_number_three.id = people.id/)
    end

    it 'generates an expression with multiple with calls' do
      query = Person.with(lucky_number_seven: Person.where(lucky_number: 7)).with(lucky_number_three: Person.where(lucky_number: 3)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id').joins('JOIN lucky_number_three ON lucky_number_three.id = people.id')
      _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "lucky_number_three" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 3\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id JOIN lucky_number_three ON lucky_number_three.id = people.id/)
    end

    it 'generates an expression with recursive' do
      query = Person.with.recursive(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
      _(query.to_sql).must_match(/WITH RECURSIVE "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
    end

    describe 'PostgreSQL server supports materialization specifiers' do
      it 'generates an expression with materialized' do
        query = Person.with.materialized(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
        _(query.to_sql).must_match(/WITH "lucky_number_seven" AS MATERIALIZED \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
      end

      it 'generates an expression with a mix of materializeds' do
        query = Person.with(lucky_number_seven: Person.where(lucky_number: 7)).with.materialized(another_lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
        _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "another_lucky_number_seven" AS MATERIALIZED \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
      end

      it 'generates an expression with not_materialized' do
        query = Person.with.not_materialized(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
        _(query.to_sql).must_match(/WITH "lucky_number_seven" AS NOT MATERIALIZED \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
      end

      it 'generates an expression with a mix of not_materializeds' do
        query = Person.with(lucky_number_seven: Person.where(lucky_number: 7)).with.not_materialized(another_lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
        _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "another_lucky_number_seven" AS NOT MATERIALIZED \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
      end

      it 'generates an expression with a mix of materializeds and not_materializeds' do
        query = Person.with.materialized(lucky_number_seven: Person.where(lucky_number: 7)).with.not_materialized(another_lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
        _(query.to_sql).must_match(/WITH "lucky_number_seven" AS MATERIALIZED \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "another_lucky_number_seven" AS NOT MATERIALIZED \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
      end
    end

    describe 'PostgreSQL server does not support materialization specifiers' do
      def without_materialization_specifiers(&block)
        CtesInMyPg.stub(:supports_materialization_specifiers?, false, &block)
      end

      it 'generates an expression with materialized' do
          without_materialization_specifiers do
            query = Person.with.materialized(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
            _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
          end
      end

      it 'generates an expression with a mix of materializeds' do
        without_materialization_specifiers do
          query = Person.with(lucky_number_seven: Person.where(lucky_number: 7)).with.materialized(another_lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
          _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "another_lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
        end
      end

      it 'generates an expression with not_materialized' do
        without_materialization_specifiers do
          query = Person.with.not_materialized(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
          _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
        end
      end

      it 'generates an expression with a mix of not_materializeds' do
        without_materialization_specifiers do
          query = Person.with(lucky_number_seven: Person.where(lucky_number: 7)).with.not_materialized(another_lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
          _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "another_lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
        end
      end

      it 'generates an expression with a mix of materializeds and not_materializeds' do
        without_materialization_specifiers do
          query = Person.with.materialized(lucky_number_seven: Person.where(lucky_number: 7)).with.not_materialized(another_lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
          _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\), "another_lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
        end
      end
    end

    it 'accepts Arel::SelectManagers' do
      arel_table = Arel::Table.new 'test'
      arel_manager = arel_table.project arel_table[:foo]

      query = Person.with(testing: arel_manager)
      _(query.to_sql).must_equal 'WITH "testing" AS (SELECT "test"."foo" FROM "test") SELECT "people".* FROM "people"'
    end

    it 'correctly quotes the identifiers' do
        query = Person.with( '"DROP DATABASE test;' => Person.where(lucky_number: 7))
        _(query.to_sql).must_equal 'WITH """DROP DATABASE test;" AS (SELECT "people".* FROM "people" WHERE "people"."lucky_number" = 7) SELECT "people".* FROM "people"'
    end
  end

  describe '.with(common_table_exression_arel_nodes_as)' do
    it 'generates an expression with the CTE' do
      table_def = CtesInMyPg::SqlLiteral.new("update_cte(id, new_lucky)")
      new_values = "(1,12),(2,3),(3,8)"

      select = CtesInMyPg::SqlLiteral.new( "(VALUES #{new_values})" )
      with = Arel::Nodes::As.new(table_def, select)

      regex_safe = new_values.gsub("(","\\(").gsub(")","\\)")

      query = Person.with(with).joins('JOIN update_cte ON update_cte.id = people.id')
      _(query.to_sql).must_match(/WITH "update_cte\(id, new_lucky\)" AS \(VALUES #{regex_safe}\) SELECT \"people\".* FROM \"people\" JOIN update_cte ON update_cte.id = people.id/)
    end

    it 'generates an expression mixed with multiple with calls' do
      table_def = CtesInMyPg::SqlLiteral.new("update_cte(id, new_lucky)")
      new_values = "(1,12),(2,3),(3,8)"

      select = CtesInMyPg::SqlLiteral.new("(VALUES #{new_values})")
      with = Arel::Nodes::As.new(table_def, select)

      regex_safe = new_values.gsub("(","\\(").gsub(")","\\)")

      query = Person.with(with).with(lucky_number_seven: Person.where(lucky_number: 7)).joins('JOIN update_cte ON update_cte.id = people.id').joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
      _(query.to_sql).must_match(/WITH "update_cte\(id, new_lucky\)" AS \(VALUES #{regex_safe}\), "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT \"people\".* FROM \"people\" JOIN update_cte ON update_cte.id = people.id JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
    end
  end

  #describe '.from_cte(common_table_expression_hash)' do
  #  it 'generates an expression with the CTE as the main table' do
  #    query = Person.from_cte('lucky_number_seven', Person.where(lucky_number: 7)).where(id: 5)
  #    query.to_sql.must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "lucky_number_seven".* FROM "lucky_number_seven"(\s+)WHERE "lucky_number_seven"."id" = 5/)
  #  end

  #  it 'returns instances of the model' do
  #    3.times { Person.create! lucky_number: 7 }
  #    3.times { Person.create! lucky_number: 3 }
  #    people = Person.from_cte('lucky_number_seven', Person.where(lucky_number: 7))

  #    people.count.must_equal 3
  #    people.first.lucky_number.must_equal 7
  #  end

  #  it 'responds to table_name' do
  #    people = Person.from_cte('lucky_number_seven', Person.where(lucky_number: 7))

  #    people.model_name.must_equal 'Person'
  #  end
  #end

  describe '.merge(Model.with(common_table_expression_hash))' do
    it 'keeps the CTE in the merged request' do
      query = Person.all.merge(Person.with(lucky_number_seven: Person.where(lucky_number: 7))).joins('JOIN lucky_number_seven ON lucky_number_seven.id = people.id')
      _(query.to_sql).must_match(/WITH "lucky_number_seven" AS \(SELECT "people".* FROM "people"(\s+)WHERE "people"."lucky_number" = 7\) SELECT "people".* FROM "people" JOIN lucky_number_seven ON lucky_number_seven.id = people.id/)
    end
  end

end
