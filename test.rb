#!/usr/bin/env ruby

$LOAD_PATH.unshift File.dirname(__FILE__)+'/lib'

require 'rubygems'
require 'telegraph'

options do
  on('-t', '--test [TEST]') {|val| set :test, val }
end

before { say "foo" }
after(:foo) { say "bar" }

handle /^HELLO/ do 
  "HI DUDE!" # returned value is answer
end

handle /^TEST (.*)/, :with => [:test] do 
  session[:test] = params[:test]
  say_ok # shortcut for "OK\n"
end

handle :foo, :match => /^FOO .*/ do 
  say "This is SPARTA!"
  say "Kick!"
  session[:test]
end
