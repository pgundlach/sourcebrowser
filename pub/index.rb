#!/bin/sh
export PATH=$RUBY:$PATH
ruby <<EORUBY

require 'cgi'

$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

begin
  require 'sourcebrowser'

  path,params=ENV['REQUEST_URI'].split('?')
  sb=Sourcebrowser.new(path,params)
  CGI.new("html4").out {  sb.out }
rescue Exception => e
  CGI.new("html4").out {
    "Internal Error - please restart the application!"
  }
end
EORUBY
