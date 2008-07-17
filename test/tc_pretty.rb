#!/usr/bin/env ruby
#
#  Created by Patrick Gundlach on 2006-10-25.
#  Copyright (c) 2006. All rights reserved.

require "test/unit"
$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require "pgpretty"

class TestPgpretty < Test::Unit::TestCase
  def test_search
    src=%q{%   {chapter : \hbox to \hsize{\strut\bf#2\hss#3}\endgraf\placelist[section]}}
    p=PGPretty.new(src)
    assert_equal("<span class=\"comment\">%   {chapter : \\hbox to \\hsize{\\strut\\bf#2\\hss#3}\\endgraf\\placelist[<span class=\"highlight\">section</span>]}</span>", p.tex("section"))
  end
end