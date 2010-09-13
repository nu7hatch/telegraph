# Telegraph framework

Telegraph is an simple DSL useful for creating TCP servers. It's working 
on EventMachine and is inspired by Sinatra - just as there, requests are 
handled by blocks assigned to specific patterns.

## Gettings started

Install the telegraph on your system using rubygms:

    sudo gem install telegraph

On Debian/Ubuntu you can install telegraph using apt:

    sudo apt-get install libtelegraph-ruby

Simple application can look like this one: 

    # myserver.rb
    require 'rubygems' # only if you are using rubygems
    require 'telegraph'
    
    handle /^HELLO$/ do
      "HELLO DUDE!"
    end

Run server: 

    ruby myserver.rb -p 1234
    
Now you can connect with your server on port 1234 eg. using telnet. 

### Handlers

You can handle each message that matches given pattern. Patterns can be 
strings or regexps. Each handler is associated with a block like below:

    handle /^FOO$/ do
      .. return something ..
    end
    
    handle "BAR" do
      .. return something ..
    end
    
Handlers are matched in the order are defined. The first handler that matches
the request is invoked. 

You can specify named aliases for pattern parameters: 

    handle /^FOO (\w+) (\w+)/, :with => [:id] do
      puts params[:id]
      puts params[2]
    end
    
... now after request like `FOO hello world` it will produce:

    hello
    world

There is also ability to define named handlers, like this:

    handle :foo, :match => /^FOO (\w+)/ do 
      "Hello!"
    end

### Answering

When the last value returned by handler's block is an string, then will 
be automatically sent to the client. Otherwise nothing will be sent. For 
example: 

    handle /^FOO/ do 
      "bar"
    end
    
... will send the `bar` answer to the client. 

Another, the easiest way to manualy sending answers is the `#answer` method
(or `#say` alias for it):

    handle /^FOO/ do
      answer("This is SPARTA!")
    end
    
... above code will produce the `This is SPARTA!\n` answer. Notice that newline
is automaticaly added to given text.  

To send raw data use `#send` method:

    handle /^FOO/ do 
      send "This"
      send "is"
      send "SPARTA!\n"
    end

Answers can be also sent with shortuct methods which are starts from `#answer_` 
or `#say_` prefixes, eg. 

    handle /^FOO/ do 
      answer_ok
    end    
    
    handle /^BAR/ do 
      answer_foo_bar("blah")
    end 
    
The first one example will send `OK\n` to the client, the second one `FOO_BAR blah\n`. 

### Filters

Before filters are evaluated before each request within the context of 
the request and can modify the request or send answers to client. 
Instance variables set in filters are accessible by routes and templates:

    before do
      @answer = 'Whazzzzup!?'
      params[:foo] = 'bar'
    end

    handle "HELLO" do
      @answer # => 'Whazzzzup!?'
      params[:foo] # => 'bar'
    end
    
After filter are evaluated after each request within the context of 
the request and can modify the request or send answers to client. 
Instance variables set in before filters and handlers are accessible 
by after filters:

    after do
      puts params[:foo]
    end

Before and after filters can be assigned to specified handler, like here:

    before :foo do 
      @foo = true
    end 
    
    after :foo do 
      @foo = false
    end
    
    before /^BAR/ do 
      @bar = true
    end
    
    handle :foo, :match => /^FOO/ do
      @foo # => true
    end
    
    handle /^BAR/ do 
      @foo # => false
      @bar # => true
    end

### Helpers

Use the top-level helpers method to define helper methods for use in handlers 
and filters:

    helpers do 
      def hello(what)
        "Hello #{what}!"
      end
    end
    
    handle /^Hi! I'm (\w+)/, :with => [:name] do 
      hello(params[:name])
    end

### Configuration

Run once, at startup, in any environment. To add an option use the `#set` method
(For boolean values You can use `#enable` and `#disable` methods):

    configure do
      set :foo, 'bar'
      enable :bar
      disable :yadayada
    end
  
Run only when the environment (or `TELEGRAPH_ENV` const or environment variable) 
is set to `:production`:

    configure :production do
      ...
    end

Run when the environment is set to either `:production` or `:test`:

    configure :production, :test do
      ...
    end

To get access to configuration from your handler or filter just use `config`
method: 

    before do 
      puts config.environment
    end
    
    handler "FOO" do
      puts config.host
    end 

There is also few special settings, which are affecting application 
behavior. Those settings are eg. 

* `:environment` - defines in which environment your application will be launched,  
* `:host` - your server will bind to this host, 
* `:port` - ypplication will be listening on this port,
* `:debug` - when true then debug mode is enabled. 

*WARNING!* The settings `:app_file`, `:run` and `:running` are used by 
Telegraph core and *SHOULD NEVER* been defined in your application.

### Testing...

TODO...

### Command-line options

Thanx to Telegraph you can easy define available command line options,
just like below. 

    options do 
      on("-t", "--test [TEST]") {|val| set :test, val }
    end

The `#on` method called inside the `options` block belongs to an
`OptionParser` object assigned to application. For more information
check docs of *optparse* standard library. You can find it 
[here](http://ruby-doc.org/stdlib/libdoc/optparse/rdoc/index.html).

Tlegraph has also few built in options, which can modify the application 
behavior:

* `-h/--host [HOST]` - sets given host name in app settings,
* `-p/--port [PORT]` - sets given port in app settings,
* `-e/--env [ENVIRONMENT]` - runs application within given environment, 
* `-d/--debug` - enables debug mode.

REMEMBER! You *shouldn't overwrite* these options in your application. 

## Note on Patches/Pull Requests
 
* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in 
  a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

## Copyright

Copyright (c) 2010 Kriss 'nu7hatch' Kowalik. See LICENSE for details.
