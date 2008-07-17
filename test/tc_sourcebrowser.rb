#!/usr/bin/env ruby -w

require "test/unit"

$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require "sourcebrowser"

class TestSourcebrowser < Test::Unit::TestCase
  def test_init
   sb=Sourcebrowser.new("/foo")
   assert_equal("foo", sb.path)

   sb=Sourcebrowser.new("foo")
   assert_equal("foo", sb.path)

   
  end
end