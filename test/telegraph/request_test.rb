require "teststrap"

context "An Request" do
  helper(:handler) { Telegraph::Handler } 
  setup { Telegraph::Request }
  
  context "on create" do 
    asserts("when given data it's set query") {
      topic.new(["FOO bar\n"]).query
    }.equals("FOO bar\n")
    
    asserts("when given handler it's set handler") {
      topic.new(["FOO"], handler.new("FOO")).handler
    }.kind_of(Telegraph::Handler)

    asserts("when given handler it's set params discovered from query") {
      h = handler.new(/^FOO (\w+) (\d+) (\w+)/, :with => [:a, :b])
      data = h.match("FOO bar 22 spam\n")
      topic.new(data.to_a, h).params
    }.equals(:a => "bar", :b => "22", 2 => "spam")

    asserts("initialized session") {
      topic.new(["FOO"]).session
    }.equals(Thread.current)
  end
  
  context "instance" do 
    setup { topic.new([]) }
    
    asserts_topic.respond_to(:query)
    asserts_topic.respond_to(:command)
    asserts_topic.respond_to(:handler)
    asserts_topic.respond_to(:params)
    asserts_topic.respond_to(:session)
  end
end
