#!/usr/bin/env ruby
#
#  Created by Patrick Gundlach on 2006-09-18.
#  Copyright (c) 2006. All rights reserved.


require "test/unit"

$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require "pgpretty"

class TestPgpretty < Test::Unit::TestCase
	def setup
		@p=PGPretty.new
	end
	def test_case_name
		@p.source="\\foobar"
		assert_equal("<span class=\"cs\">\\foobar</span>", @p.tex)
	end
end