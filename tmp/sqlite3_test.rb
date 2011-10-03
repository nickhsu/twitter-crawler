#!/usr/bin/env ruby

require "sqlite3"

# Open a database
db = SQLite3::Database.new "test.db"

# Create a database
rows = db.execute <<-SQL
  create table numbers (
    uid varchar(30),
    visited bit
  );
SQL

# Execute a few inserts
#db.execute "insert into numbers values ( ?, ? )", pair

