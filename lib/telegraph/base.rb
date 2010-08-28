require 'eventmachine'
require 'timeout'
require 'thread'
require 'ostruct'
require 'logging'
require 'optparse'

begin
  require 'fastthread' 
rescue LoadError
  $stderr.puts("The fastthread gem not found. Using standard ruby threads.")
end

# Telegraph is an simple DSL useful for creating TCP servers. It's working 
# on EventMachine and is inspired by Sinatra - just as there, requests are 
# handled by blocks assigned to specific patterns.
module Telegraph 
  require 'telegraph/version'
  require 'telegraph/request'
  require 'telegraph/handler'

  # It creates new application based on the class specified in first parameter. 
  # Given block will be called within the newly created class. 
  #
  # By default the base class is +Telegraph::Base+. 
  #
  #   Telegraph.new do 
  #     set :foo, 'Bar'
  #     set :bar, 'Spam'
  #
  #     before { say "Ring! Ring!" }
  #
  #     handle "HELLO" do
  #       "Hello my friend!"
  #     end
  #
  #     run! # starts application
  #   end 
  #
  # Applications based on the specified class (we can call them clones) are
  # useful when we want run few servers which are doing the same jobs, eg.
  #
  #   class MyApp < Telegraph::Base
  #     .. your freaky code ..
  #   end
  #
  #   master = Telegraph.new(MyApp) { set :port, 1118 }
  #   slave  = Telegraph.new(MyApp) { set :port, 1119 }
  #
  #   EventMachine.run do
  #     master.run!
  #     slave.run!
  #   end
  def self.new(base=Base, &block)
    base = Class.new(Base)
    base.send :class_eval, &block if block_given?
    base
  end
  
  # Base class for all Telegraph applications. Within it you can define 
  # own handlers for incoming messages, filters which will be performed
  # before or after requests and allowed command line options, and manage 
  # various configuration. 
  #
  # Check the +docs+ for more information about configuration and usage. 
  class Base < EventMachine::Connection
  
    class << self
      # Starts the application within the _EventMachine reactor_. Additionaly
      # it is registering signal traps and setting up configuration. 
      def run!
        config.environment ||= TELEGRAPH_ENV if defined?(TELEGRAPH_ENV)
        config.environment ||= ENV['TELEGRAPH_ENV'] || :development
        config.host ||= 'localhost'
        config.port ||= 1234
        
        EventMachine.run do
          begin
            puts "== Telegraph is waiting for connection on #{config.host}:#{config.port} for #{config.environment}" 
            set :running, EventMachine.start_server(config.host, config.port, self)
            register_signal_traps
          rescue Errno::EADDRINUSE => e
            puts "== Someone is already performing on port #{port}!"
          end 
        end
      end
      
      # Application state checker. It returns true when application is running. 
      def run?
        !!config.run
      end 
      
      
      # Use the top-level helpers method to define helper methods for use 
      # in handlers and filters:
      #
      #  helpers do 
      #    def hello(what)
      #      "Hello #{what}!"
      #    end
      #  end
      #  
      #  handle /^Hi! I'm (\w+)/, :with => [:name] do 
      #    hello(params[:name])
      #  end
      def helpers(*extensions, &block)
        class_eval(&block)   if block_given?
        include(*extensions) if extensions.any?
      end

      # You can handle each message that matches given pattern. Patterns can be 
      # strings or regexps. Each handler is associated with a block like below:
      #
      #   handle /^FOO$/ do
      #     .. return something ..
      #   end
      #  
      #   handle "BAR" do
      #     .. return something ..
      #   end
      #    
      # Handlers are matched in the order are defined. The first handler that matches
      # the request is invoked. 
      #
      # You can specify named aliases for pattern parameters: 
      # 
      #   handle /^FOO (\w+) (\w+)/, :with => [:id] do
      #     puts params[:id]
      #     puts params[2]
      #   end
      #    
      # ... now after request like `FOO hello world` it will produce:
      # 
      #   hello
      #   world
      #
      # There is also ability to define named handlers, like this:
      #
      #   handle :foo, :match => /^FOO (\w+)/ do 
      #     "Hello!"
      #   end
      def handle(pattern, options={}, &block)
        block_given? or raise ArgumentError, "No block given"
        @handlers ||= {}
        @handlers[pattern] = Telegraph::Handler.new(pattern, options, &block)
      end
      
      # It returns struct with all defined filters.
      #
      #   Telegraph::Base.filters[:before] #=> before filters...
      #   Telegraph::Base.filters[:after]  #=> after filters...
      def filters
        @filters ||= {:before => {}, :after => {}}
      end
      
      # It returns all defined handlers, where as keys are used handler names 
      # or paths.  
      def handlers
        @handlers ||= {}
      end
      
      # It defines filter which will be called before perform handler for
      # received message.  
      #
      #   before do 
      #     say "BYE!"
      #   end
      #
      # Such filter can be directly assigned to specified handler, like here:
      #
      #   before :foo do 
      #     say "BYE FOO!"
      #   end
      #   
      #   after /^BAR/do 
      #     say "BYE BAR!"
      #   end
      #
      # See also the +#after+ method.
      def before(handler=false, meth=nil, &block)
        add_filter(:before, handler, meth, &block)
      end
      
      # It defines filter which will be called after perform handler for
      # received message.  
      #
      #   after do 
      #     say "BYE!"
      #   end
      #
      # Such filter can be directly assigned to specified handler, like here:
      #
      #   after :foo do 
      #     say "BYE FOO!"
      #   end
      #   
      #   after /^BAR/do 
      #     say "BYE BAR!"
      #   end
      #
      # See also the +#before+ method.  
      def after(handler=false, meth=nil, &block)
        add_filter(:after, handler, meth, &block)
      end
      
      # It returns the structure containing all application settings. It's
      # also aliased by +#settings+ method. 
      #
      #   set :host, "myhost.com"
      #   enable :foo
      #   config.host   # => "myhost.com"
      #   config.foo    # => true
      #   settings.host # => "myhost.com" 
      def config
        @config ||= OpenStruc.new
      end
      alias_method :settings, :config
      
      # Run once, at startup, in any environment. To add an option use the 
      # +set+ method (For boolean values You can use +#enable+ and 
      # +#disable+ methods):
      # 
      #   configure do
      #     set :foo, 'bar'
      #     enable :bar
      #     disable :yadayada
      #   end
      #   
      # Run only when the environment (or +TELEGRAPH_ENV+ const or environment
      # variable) is set to +:production+:
      # 
      #   configure :production do
      #     ...
      #   end
      #
      # Run when the environment is set to either +:production+ or +:test+:
      # 
      #   configure :production, :test do
      #     ...
      #   end
      def configure(*envs, &block)
        yield self if envs.empty? || envs.include?(environment.to_sym)      
      end
      
      # Shortcut to +settings.environment+. It returns name of current
      # runtime environment. 
      def environment
        config.environment ||= :development
      end
      
      # Assigns given value to the specified setting key. 
      #
      #   set :app_name, "YadaYadaYaday!"
      #   set :host, "myhost.com"
      #   set :port, 666
      #
      # See also shortcuts for boolean settings: +#enable+ and +#disable+ methods. 
      def set(name, value)
        config.send "#{name}=", value
      end
      
      # It "enables" given setting. It means that it assigns +true+ value
      # to the specified setting key.
      #
      #   enable :foo # => set :foo, true
      #
      # See also +#set+ and +#disable+ methods.  
      def enable(name)
        set name, true
      end
      
      # It "disables" given setting. It means that it assigns +false+ value
      # to the specified setting key. 
      #
      #   disable :foo # => set :foo, true
      #
      # See also +#set+ and +#enable+ methods.    
      def disable(name)
        set name, false
      end

      # Inside this block you can define your own additional command line 
      # options, eg. 
      # 
      #   options do 
      #     on("-t", "--test [TEST]") {|val| set :test, val }
      #     on("-f", "--foo") {|val| enable :test }
      #   end
      # 
      # The +#on+ method called inside the  block belongs to an +OptionParser+ 
      # object assigned to application. For more information check docs 
      # of *optparse* standard library. You can find it here: 
      def options(&block)
        @@options = OptionParser.new unless defined?(@@options)
        @@options.send(:instance_eval, &block) if block_given?
        @@options
      end
      
      # Returns objects which is responsible for system logging. If you want set
      # your own logger then it have to be compatible with *logging* library.  
      def logger
        logger ||= Logging.logger[self]
      end
      
      protected
      
      # Defines given filter. 
      def add_filter(kind, handler=false, meth=nil, &block)
        if handler.is_a?(Symbol) && meth.nil? && !block_given?
          meth = handler
          handler = false
        end
        filters[kind] ||= {}
        filters[kind][handler] ||= []
        filters[kind][handler] << (meth || block)
      end
      
      private
      
      # Sets traps for closing signals. The defined traps are stopping all 
      # running reactors and cleaning up active connections. 
      def register_signal_traps
        [:INT, :TERM].each {|sig| trap(sig) { 
          puts "\n== Cleaning up..."
          EventMachine.stop_server(config.running) if !!config.running
          EventMachine.stop
        }}
      end
    end
    
    # This method is called automatically imedietely after connection with 
    # client will be established. 
    def post_init
      logger.debug "Listening from #{client_name}"
    end
    
    # This method is called automatically when closing connection 
    # with client.
    def unbind
      logger.debug "Connection with #{client_name} has been closed"
    end
    
    # This method is called automatically when the server is receiving 
    # data from the connected client, eg...
    #
    #   telnet localhost 1234
    #   telnet> hello
    #
    # ... will perform +#receive_data+ method with +"hello\n"+ argument on the
    # server. 
    def receive_data(data)
      logger.info "#{client_name} is saying: #{data.to_s.chomp.strip}"
      begin
        self.class.handlers.each do |key, handler|
          if match = handler.match(data)
            @request = Telegraph::Request.new(match, handler)
            process_filters :before, handler
            result = instance_eval(&handler.block) and say(result)
            process_filters :after, handler
            return result
          end
        end
      rescue Exception => ex
        logger.error "Error while dispatching data: #{ex}\n\t#{ex.backtrace.join("\n\t")}"
        say "ERROR #{ex}"
      end
    end
    
    # It returns object which contains complete information about 
    # actual processed request. 
    def request
      @request ||= Telegraph::Request.new
    end
    
    # Shortcuts to few commonly used request methods:  
    #
    # +session+:: current client session
    # +query+ lub +command+:: current received command
    # +params+:: parameters husked from received command 
    
    %w{session query params command}.each do |meth|
      eval <<-RUBY, binding, '(__BASE__)', 1
        def #{meth}
          request.#{meth}
        end
      RUBY
    end
    
    # Instance shortcuts to most commonly used class methdos: 
    # 
    # +config+:: application settings hash
    # +settings+:: alias for +#config+ 
    # +options+:: command line options
    # +logger+:: application logger 
    # +environment+:: current runtime environment
    
    %w{config settings options logger environment}.each do |meth|
      eval <<-RUBY, binding, '(__BASE__)', 1
        def #{meth}(*args, &block)
          self.class.#{meth}(*args, &block)
        end
      RUBY
    end
    
    # Shortcuts to quick check in which environment applicaiton has been 
    # launched:
    #
    #   test?         # => config.environment == :test
    #   development?  # => config.environment == :development
    #   production?   # => config.environment == :procution
    
    %w{development test production}.each do |env| 
      eval <<-RUBY, binding, '(__BASE__)', 1
        def #{env}?
          config.environment.to_s == #{env.to_s.inspect}
        end
      RUBY
    end
    
    # Sends given raw data to the connected client. 
    #
    #   send "Hello my friend!"
    #   send "How are you?\n"
    def send(data)
      logger.debug "Sending data to #{client_name}: #{data.to_s.chomp.strip}"
      send_data(data) and nil
    end
    
    # Sends given answer with added newline at the end to the connected client.
    #
    #   answer "Hello buddy" # it will send "Hello buddy\n" to the client
    #   say "Whazzuup?"      # equivalent to: answer("Whazzuup?")
    def answer(data)
      data and send("#{data.to_s}\n") rescue nil
    end
    alias_method :say, :answer
    
    # You can send answers using following style syntactic sugars. Allowed 
    # shortcuts have +say_+ or +answer_" prefix and sends to the client 
    # rest of it name (capitalized), eg.
    #     
    #   say_hello_world        # equivalent to: say "HELLO_WORLD"
    #   say_this_is_sparta     # equivalent to: say "THIS_IS_SPARTA"
    #   answer_ok              # equivalent to: say "OK"
    #   answer_foo_bar("blah") # equivalent to: say "FOO_BAR blah"
    
    def method_missing(meth, *args, &block) # :nodoc:
      if meth.to_s =~ /\A(say|answer)_(.+)/
        if args.size > 0 
          say("#{$2.upcase} #{args.flatten.join(" ")}")
        else
          say("#{$2.upcase}")
        end
      else
        super
      end
    end
    
    protected
    
    # Name which is identifying connected client (for now it host and port).  
    def client_name
      @client_name ||= begin
        port, ip = Socket.unpack_sockaddr_in(get_peername)
        "#{ip}:#{port}"
      end
    end

    # Sytactic sugar for +#close_connection+ method. It closes current 
    # connection with the client. 
    #
    #   handle /^(QUIT|EXIT|CLOSE)/ do
    #     say "BYE!"
    #     close!
    #   end    
    def close!
      close_connection
    end
    
    private
    
    # Runs all filters of given kind within the handler context. You should 
    # notice that global filters are treated like filters from given group.   
    def process_filters(kind, handler)
      if filters.key?(kind)
        group = filters[kind][false].to_a.clone
        group.concat(filters[kind][handler.name] || [])
        group.each do |filter|
          filter and (filter.is_a?(Symbol) ? method(filter).call : instance_eval(&filter))
        end
      end
    end
    
    # Shortcut to +#filters+ class method. See it docs for more info.  
    def filters
      self.class.filters
    end
  end # Base
end # Telegraph
