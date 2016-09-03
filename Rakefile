require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb']
end

task :default => :test

namespace :db do
  task :load_db_settings do
    require 'active_record'
    unless ENV['DATABASE_URL']
      require 'dotenv'
      Dotenv.load
    end
  end

  task :drop => :load_db_settings do
    %x{ dropdb #{ENV['DATABASE_NAME']} }
  end

  task :create => :load_db_settings do
    %x{ createdb #{ENV['DATABASE_NAME']} }
  end

  task :migrate => :load_db_settings do
    ActiveRecord::Base.establish_connection

    ActiveRecord::Base.connection.enable_extension 'hstore'

    ActiveRecord::Base.connection.create_table :people, force: true do |t|
      t.inet     "ip"
      t.cidr     "subnet"
      t.integer  "tag_ids",      array: true
      t.string   "tags",         array: true
      t.hstore   "data"
      t.integer  "lucky_number"
      t.datetime "created_at"
      t.datetime "updated_at"
    end

    ActiveRecord::Base.connection.create_table :people_tags, force: true do |t|
      t.integer  "person_id"
      t.integer  "tag_id"
    end

    ActiveRecord::Base.connection.create_table :tags, force: true do |t|
      t.integer  "person_id"
      t.string   "categories",         array: true
      t.datetime "created_at"
      t.datetime "updated_at"
      t.integer  "parent_id"
      t.string   "type"
    end

    puts 'Database migrated'
  end
end
