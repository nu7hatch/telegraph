module Telegraph
  # Object of this class contains complete information about actual processed 
  # request. It also manages current client session.  
  class Request
    # Content of the recevied command. 
    attr_reader :query
    alias :command :query
    
    # Parameters which has been husked from the received command upon a
    # pattern defined in handler.  
    attr_reader :params
    
    # Actual client session. In fact it's object of current thread in which 
    # received message has been processed.  
    attr_reader :session
    
    # Handler matched to received command. 
    attr_reader :handler
    
    def initialize(data=nil, handler=nil)
      @query   = data.shift
      @handler = handler
      @session = Thread.current
      @params  = {}
      
      discover_params(data) if @handler && @query
    end

    protected
    
    # Creates hash with parameters husked from command.  
    def discover_params(data)
      keys = @handler.options[:with] || []
      data.each_with_index {|param, id| @params[(keys.shift or id)] = param }
    end 
  end # Request
end # Telegraph
