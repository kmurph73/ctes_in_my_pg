$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)

require 'active_record'
require 'ctes_in_my_pg'

require 'minitest/autorun'

require 'bourne'
require 'database_cleaner'

require 'byebug'

require 'dotenv'
Dotenv.load

ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'])

class Person < ActiveRecord::Base
  has_many :hm_tags, class_name: 'Tag'
  has_and_belongs_to_many :habtm_tags, class_name: 'Tag'

  def self.wicked_people
    includes(:habtm_tags)
      .where(:tags => {:categories => ['wicked','awesome']})
  end
end

class Tag < ActiveRecord::Base
  belongs_to :person
end

class ParentTag < Tag
end

class ChildTag < Tag
  belongs_to :parent_tag, foreign_key: :parent_id
end

DatabaseCleaner.strategy = :deletion

class MiniTest::Spec
  class << self
    alias :context :describe
  end

  before do
    DatabaseCleaner.start
  end

  after do
    DatabaseCleaner.clean
  end
end
