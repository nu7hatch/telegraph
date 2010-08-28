require "teststrap"

context "A Telegraph" do 
  setup { Telegraph }
  
  asserts("version") { 
    topic::VERSION 
  }.equals("0.2.0")
  
  asserts("#new method returns class which ancestors") { 
    topic.new.ancestors 
  }.includes(Telegraph::Base)
end
