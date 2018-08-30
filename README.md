# CtesInMyPg

[postgres_ext][1], a great gem, does not support Rails 5 yet.  

Since I only ever use [CTEs][2] from that gem, I thought I'd rip out the code for that and put it in a separate gem to get CTEs working with Rails & ActiveRecord 5.

***All credit goes to [Dan McClain][3] and the postgres_ext contributors*** ... I just stole the code ... though I did remove `alias_method_chain`!

It works with Rails 5 & 5.1 for sure.  If you want guaranteed CTE support below that, use the postgres_ext gem.

**Rails 5.2 support is on the `rails-5-2-0` branch.**  `ActiveRecord::Relation#build_arel`'s [arity changed in Rails 5.2.0](https://github.com/kmurph73/ctes_in_my_pg/issues/2), breaking this gem.

If you're using Rails 5.2, please install via: 

```ruby
gem 'ctes_in_my_pg', github: 'kmurph73/ctes_in_my_pg', branch: 'rails-5-2-0'
```

[1]: https://github.com/DockYard/postgres_ext
[2]: https://www.postgresql.org/docs/current/static/queries-with.html
[3]: https://github.com/danmcclain

# Common Table Expressions (CTEs)

ctes_in_my_pg adds CTE expression support to ActiveRecord via:

  * [`Relation#with`](#with)

## with

We can add CTEs to queries by chaining `#with` off a relation.
`Relation#with` accepts a hash, and will convert `Relation`s to the
proper SQL in the CTE.

Let's expand a `#with` call to its resulting SQL code:

```ruby
Score.with(my_games: Game.where(id: 1)).joins('JOIN my_games ON scores.game_id = my_games.id')
```

The following will be generated when that relation is evaluated:

```SQL
WITH my_games AS (
SELECT games.*
FROM games
WHERE games.id = 1
)
SELECT *
FROM scores
JOIN my_games
ON scores.games_id = my_games.id
```

You can also do a recursive with:

```ruby
Graph.with.recursive(search_graph:
  "  SELECT g.id, g.link, g.data, 1 AS depth
     FROM graph g
   UNION ALL
     SELECT g.id, g.link, g.data, sg.depth + 1
     FROM graph g, search_graph sg
     WHERE g.id = sg.link").from(:search_graph)
```
  * [`Model.from_cte`](#from_cte)

## no Model.from_cte

no support for postgre_ext's [from_cte](https://github.com/DockYard/postgres_ext/blob/master/docs/querying.md#from_cte) because I couldn't get it working and I don't really see the point of it anyway

PRs for `from_cte` support are of course welcome however

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ctes_in_my_pg', github: 'kmurph73/ctes_in_my_pg'
```

For Rails 5.2+:

``` ruby
gem 'ctes_in_my_pg', github: 'kmurph73/ctes_in_my_pg', branch: 'rails-5-2-0'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ctes_in_my_pg

## Development

After checking out the repo, run `bin/setup` to install dependencies. 

To run the tests, create a PG db then put `DATABASE_URL="postgres://[YOUR_USERNAME]:@localhost/somedb"` in .env.  Then run `bundle exec rake db:migrate`.

Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/kmurph73/ctes_in_my_pg.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

