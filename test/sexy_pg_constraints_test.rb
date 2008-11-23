require File.dirname(__FILE__) + '/test_helper.rb'

# Database spc_test should be created manually.
ActiveRecord::Base.establish_connection(:adapter => "postgresql", :database => "spc_test")

# Setting sample up migrations
class CreateBooks < ActiveRecord::Migration
  def self.up
    create_table :books do |t|
      t.string  :title
      t.string  :author
      t.integer :quantity
      t.string  :isbn
    end
  end
  
  def self.down
    drop_table :books
  end
end

class Book < ActiveRecord::Base; end

class SexyPgConstraintsTest < Test::Unit::TestCase
  def setup
    CreateBooks.up
  end
  
  def teardown
    CreateBooks.down
  end
  
  def test_should_create_book
    Book.create
    assert_equal Book.count, 1
  end
  
  def test_whitelist
    ActiveRecord::Migration.constrain :books, :author, :whitelist => %w(whitelisted1 whitelisted2 whitelisted3)
    
    assert_prohibits :author, :whitelist do |book|
      book.author = 'not_whitelisted'
    end
    
    assert_allows do |book|
      book.author = 'whitelisted2'
    end
    
    ActiveRecord::Migration.deconstrain :books, :author, :whitelist
    
    assert_allows do |book|
      book.author = 'not_whitelisted'
    end
  end
  
  def test_blacklist
    ActiveRecord::Migration.constrain :books, :author, :blacklist => %w(blacklisted1 blacklisted2 blacklisted3)
    
    assert_prohibits :author, :blacklist do |book|
      book.author = 'blacklisted2'
    end
    
    assert_allows do |book|
      book.author = 'not_blacklisted'
    end
    
    ActiveRecord::Migration.deconstrain :books, :author, :blacklist
    
    assert_allows do |book|
      book.author = 'blacklisted2'
    end
  end
  
  def test_not_blank
    ActiveRecord::Migration.constrain :books, :author, :not_blank => true
    
    assert_prohibits :author, :not_blank do |book|
      book.author = ' '
    end
    
    assert_allows do |book|
      book.author = 'foo'
    end
    
    ActiveRecord::Migration.deconstrain :books, :author, :not_blank
    
    assert_allows do |book|
      book.author = ' '
    end
  end
  
  def test_within_inclusive
    ActiveRecord::Migration.constrain :books, :quantity, :within => 5..11
    
    assert_prohibits :quantity, :within do |book|
      book.quantity = 12
    end
    
    assert_prohibits :quantity, :within do |book|
      book.quantity = 4
    end
    
    assert_allows do |book|
      book.quantity = 7
    end
    
    ActiveRecord::Migration.deconstrain :books, :quantity, :within
    
    assert_allows do |book|
      book.quantity = 12
    end
  end
  
  def test_within_non_inclusive
    ActiveRecord::Migration.constrain :books, :quantity, :within => 5...11
    
    assert_prohibits :quantity, :within do |book|
      book.quantity = 11
    end
    
    assert_prohibits :quantity, :within do |book|
      book.quantity = 4
    end
    
    assert_allows do |book|
      book.quantity = 10
    end
    
    ActiveRecord::Migration.deconstrain :books, :quantity, :within
    
    assert_allows do |book|
      book.quantity = 11
    end
  end
  
  def test_length_within_inclusive
    ActiveRecord::Migration.constrain :books, :title, :length_within => 5..11
    
    assert_prohibits :title, :length_within do |book|
      book.title = 'abcdefghijkl'
    end
    
    assert_prohibits :title, :length_within do |book|
      book.title = 'abcd'
    end
    
    assert_allows do |book|
      book.title = 'abcdefg'
    end
    
    ActiveRecord::Migration.deconstrain :books, :title, :length_within
    
    assert_allows do |book|
      book.title = 'abcdefghijkl'
    end
  end
  
  def test_length_within_non_inclusive
    ActiveRecord::Migration.constrain :books, :title, :length_within => 5...11
    
    assert_prohibits :title, :length_within do |book|
      book.title = 'abcdefghijk'
    end
    
    assert_prohibits :title, :length_within do |book|
      book.title = 'abcd'
    end
    
    assert_allows do |book|
      book.title = 'abcdefg'
    end
    
    ActiveRecord::Migration.deconstrain :books, :title, :length_within
    
    assert_allows do |book|
      book.title = 'abcdefghijk'
    end
  end
  
  def test_email
    ActiveRecord::Migration.constrain :books, :author, :email => true
    
    assert_prohibits :author, :email do |book|
      book.author = 'blah@example'
    end
    
    assert_allows do |book|
      book.author = 'blah@example.com'
    end
    
    ActiveRecord::Migration.deconstrain :books, :author, :email
    
    assert_allows do |book|
      book.author = 'blah@example'
    end
  end 
  
  def test_alphanumeric
    ActiveRecord::Migration.constrain :books, :title, :alphanumeric => true
    
    assert_prohibits :title, :alphanumeric do |book|
      book.title = 'asdf@asdf'
    end
    
    assert_allows do |book|
      book.title = 'asdf'
    end
    
    ActiveRecord::Migration.deconstrain :books, :title, :alphanumeric
    
    assert_allows do |book|
      book.title = 'asdf@asdf'
    end
  end
  
  def test_positive
    ActiveRecord::Migration.constrain :books, :quantity, :positive => true
    
    assert_prohibits :quantity, :positive do |book|
      book.quantity = -1
    end
    
    assert_allows do |book|
      book.quantity = 1
    end
    
    ActiveRecord::Migration.deconstrain :books, :quantity, :positive
    
    assert_allows do |book|
      book.quantity = -1
    end
  end
  
  def test_unique
    ActiveRecord::Migration.constrain :books, :isbn, :unique => true
    
    assert_allows do |book|
      book.isbn = 'foo'
    end
    
    assert_prohibits :isbn, :unique, 'unique' do |book|
      book.isbn = 'foo'
    end
    
    ActiveRecord::Migration.deconstrain :books, :isbn, :unique
    
    assert_allows do |book|
      book.isbn = 'foo'
    end
  end
  
  def test_exact_length
    ActiveRecord::Migration.constrain :books, :isbn, :exact_length => 5
    
    assert_prohibits :isbn, :exact_length do |book|
      book.isbn = '123456'
    end
    
    assert_prohibits :isbn, :exact_length do |book|
      book.isbn = '1234'
    end
    
    assert_allows do |book|
      book.isbn = '12345'
    end
    
    ActiveRecord::Migration.deconstrain :books, :isbn, :exact_length
    
    assert_allows do |book|
      book.isbn = '123456'
    end
  end
  
  
  def test_block_syntax
    ActiveRecord::Migration.constrain :books do |t|
      t.title :not_blank => true
      t.isbn :exact_length => 15
      t.author :alphanumeric => true
    end
    
    assert_prohibits :title, :not_blank do |book|
      book.title = '  '
    end
    
    assert_prohibits :isbn, :exact_length do |book|
      book.isbn = 'asdf'
    end
    
    assert_prohibits :author, :alphanumeric do |book|
      book.author = 'foo#bar'
    end
    
    ActiveRecord::Migration.deconstrain :books do |t|
      t.title :not_blank
      t.isbn :exact_length
      t.author :alphanumeric
    end
    
    assert_allows do |book|
      book.title  = '  '
      book.isbn   = 'asdf'
      book.author = 'foo#bar'
    end
  end
  
  def test_multiple_constraints_per_line
    ActiveRecord::Migration.constrain :books do |t|
      t.title :not_blank => true, :alphanumeric => true, :blacklist => %w(foo bar)
    end
    
    assert_prohibits :title, :not_blank do |book|
      book.title = ' '
    end
    
    assert_prohibits :title, :alphanumeric do |book|
      book.title = 'asdf@asdf'
    end
    
    assert_prohibits :title, :blacklist do |book|
      book.title = 'foo'
    end
    
    ActiveRecord::Migration.deconstrain :books do |t|
      t.title :not_blank, :alphanumeric, :blacklist
    end
    
    assert_allows do |book|
      book.title = ' '
    end
    
    assert_allows do |book|
      book.title = 'asdf@asdf'
    end
    
    assert_allows do |book|
      book.title = 'foo'
    end
  end
  
  private
  def assert_prohibits(column, constraint, constraint_type = 'check')
    book = Book.new
    yield(book)
    assert book.valid?
    error = assert_raise ActiveRecord::StatementInvalid do 
      book.save 
    end
    assert_match /PGError/, error.message
    assert_match /violates #{constraint_type} constraint "books_#{column}_#{constraint}"/, error.message
  end
  
  def assert_allows
    first_count = Book.count
    book = Book.new
    yield(book)
    assert book.valid?
    assert_nothing_raised do 
      book.save
    end
    assert_equal Book.count, first_count + 1
  end
end
