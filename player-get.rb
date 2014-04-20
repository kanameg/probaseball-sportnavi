# -*- coding: utf-8 -*-

#require_relative './playerdb'
require File.dirname(__FILE__) + '/playerdb'
  
id = ARGV[0]
puts JSON.pretty_generate(PlayerDB.search(id))
#puts JSON.pretty_generate(PlayerDB.delete(id))
