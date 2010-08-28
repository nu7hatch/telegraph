module Telegraph
  # It keeps information what to do when command which matches given pattern 
  # will be received.  
  class Handler
    # Raised when pattern specified in constructor is invalid. 
    class InvalidPattern < ArgumentError; end
  
    # Handler will process received command when it will match this pattern. 
    # Pattern can be defined as string or regexp. 
    attr_reader :pattern
    
    # Additional handler's settings. 
    attr_reader :options
    
    # This block will be called within application context when received
    # data will match this handler's pattern.  
    attr_reader :block
    
    # The handler's unique name. 
    attr_reader :name
    
    def initialize(pattern, options={}, &block)
      @block   = block
      @name    = pattern
      @options = options

      case pattern
      when Symbol
        @pattern = options[:match]
      when Regexp, String
        @pattern = pattern
      else
        @pattern = nil
      end
      
      @pattern or raise InvalidPattern, "Defined pattern seems to be invalid" 
    end
    
    # Matches given command with handler's pattern.  
    def match(command)
      command.match(pattern)
    end
  end # Handler
end # Telegraph
