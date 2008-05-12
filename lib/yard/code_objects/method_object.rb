module YARD::CodeObjects
  class MethodObject < Base
    attr_accessor :visibility, :scope
    
    def initialize(namespace, name, visibility, scope) 
      super(namespace, name) do |o|
        o.visibility = visibility.to_sym
        o.scope = scope.to_sym
        yield(o) if block_given?
      end
    end
    
    protected
    
    def sep; scope == :class ? super : ISEP end
  end
end