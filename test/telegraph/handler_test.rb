require "teststrap"

context "An Handler" do
  setup { Telegraph::Handler }
  
  context "on create" do 
    asserts("when given invalid pattern") { 
      topic.new(nil) 
    }.raises(Telegraph::Handler::InvalidPattern)
    
    asserts("when given valid regexp it's set pattern") {
      topic.new(/^FOO/).pattern 
    }.equals(/^FOO/)
    
    asserts("when given valid string it's set pattern") { 
      topic.new("FOO").pattern 
    }.equals("FOO")
    
    asserts("when given opts it's set options") { 
      topic.new("FOO", 1=>2, 2=>3).options 
    }.equals(1=>2, 2=>3)
    
    asserts("when given string or regexp it's set name") { 
      topic.new("BAR").name 
    }.equals("BAR")
    
    asserts("when given symbolized name and not set or invalid pattern") { 
      topic.new(:foo) 
    }.raises(Telegraph::Handler::InvalidPattern)
    
    asserts("when given symbolized name, pattern recognized from :match option set pattern") {
      topic.new(:foo, :match => "FOO").pattern 
    }.equals("FOO")
    
    asserts("when given symbolized name it's set name") { 
      topic.new(:foo, :match => "FOO").name 
    }.equals(:foo)
    
    asserts("when given block it's set block") {
      h = topic.new("FOO") { "YadaYada" }
      h.block 
    }.kind_of(Proc)
    
    asserts("when given block it's set block result") {
      h = topic.new("FOO") { "YadaYada" }
      h.block.call 
    }.equals("YadaYada")
  end
end
