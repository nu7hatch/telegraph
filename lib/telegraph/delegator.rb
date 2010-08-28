module Telegraph
  # This module after include creates ports to all public methods of 
  # +Telegraph::Base+ class.  
  #
  #   include Telegraph::Delegator
  #   after { "YadaYada" }
  #   handle("FOO") { "Bar" }
  module Delegator
    %w{handle before after helpers configure set enable disable config settings
      development? test? production? environment options logger}.each do |meth|
        meth = meth.to_sym
        eval <<-RUBY, binding, '(__DELEGATE__)', 1
          def #{meth}(*args, &b)
            ::Telegraph::Base.send(#{meth.inspect}, *args, &b)
          end
          private #{meth.inspect}
        RUBY
      end
    end
  end # Delegator
end # Telegraph
