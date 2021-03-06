require File.dirname(__FILE__) + '/spec_helper'

describe "YARD::Handlers::Ruby::#{RUBY18 ? "Legacy::" : ""}ClassHandler" do
  before(:all) { parse_file :class_handler_001, __FILE__ }
  
  it "should parse a class block with docstring" do
    P("A").docstring.should == "Docstring"
  end
  
  it "should handle complex class names" do
    P("A::B::C").should_not == nil
  end
  
  it "should handle the subclassing syntax" do
    P("A::B::C").superclass.should == P(:String)
    P("A::X").superclass.should == Registry.at("A::B::C")
  end
  
  it "should interpret class << self as a class level block" do
    P("A.classmethod1").should_not == nil
  end
  
  it "should interpret class << ClassName as a class level block in ClassName's namespace" do
    P("A::B::C::Hello").should be_instance_of(CodeObjects::MethodObject)
  end
  
  it "should make visibility public when parsing a block" do
    P("A::B::C#method1").visibility.should == :public
  end
  
  it "should set superclass type to :class if it is a Proxy" do
    P("A::B::C").superclass.type.should == :class
  end
  
  it "should look for a superclass before creating the class if it shares the same name" do
    P('B::A').superclass.should == P('A')
  end

  it "should handle class definitions in the form ::ClassName" do
    Registry.at("MyRootClass").should_not be_nil
  end
  
  it "should handle superclass as a constant-style method (camping style < R /path/)" do
    P('Test1').superclass.should == P(:R)
    P('Test2').superclass.should == P(:R)
    P('Test6').superclass.should == P(:NotDelegateClass)
  end
  
  it "should handle superclass with OStruct.new or Struct.new syntax (superclass should be OStruct/Struct)" do
    P('Test3').superclass.should == P(:Struct)
    P('Test4').superclass.should == P(:OStruct)
  end
  
  it "should handle DelegateClass(CLASSNAME) superclass syntax" do
    P('Test5').superclass.should == P(:Array)
  end
  
  it "should handle a superclass of the same name in the form ::ClassName" do
    P('Q::Logger').superclass.should == P(:Logger)
  end
  
  ["CallMethod('test')", "VSD^#}}", 'not.aclass', 'self'].each do |klass|
    it "should raise an UndocumentableError for invalid class '#{klass}'" do
      with_parser(:ruby18) { undoc_error "class #{klass}; end" }
    end
  end
  
  ['@@INVALID', 'hi', '$MYCLASS', 'AnotherClass.new'].each do |klass|
    it "should raise an UndocumentableError for invalid superclass '#{klass}' but it should create the class." do
      YARD::CodeObjects::ClassObject.should_receive(:new).with(Registry.root, 'A')
      with_parser(:ruby18) { undoc_error "class A < #{klass}; end" }
      Registry.at('A').superclass.should == P(:Object)
    end
  end
  
  ['not.aclass', 'self', 'AnotherClass.new'].each do |klass|
    it "should raise an UndocumentableError if the constant class reference 'class << SomeConstant' does not point to a valid class name" do
      with_parser(:ruby18) do
        undoc_error <<-eof
          CONST = #{klass}
          class << CONST; end
        eof
      end
      Registry.at(klass).should be_nil
    end
  end

  it "should document 'class << SomeConstant' by using SomeConstant's value as a reference to the real class name" do
    Registry.at('String.classmethod').should_not be_nil
  end
  
  it "should allow class << SomeRubyClass to create the class if it does not exist" do
    Registry.at('Symbol.toString').should_not be_nil
  end
  
  it "should document 'class Exception' without running into superclass issues" do
    Parser::SourceParser.parse_string <<-eof
      class Exception
      end
    eof
    Registry.at(:Exception).should_not be_nil
  end
  
  it "should document 'class RT < XX::RT' with proper superclass even if XX::RT is a proxy" do
    Registry.at(:RT).should_not be_nil
    Registry.at(:RT).superclass.should == P('XX::RT')
  end
  
  it "should not overwrite docstring with an empty one" do
    Registry.at(:Zebra).docstring.should == "Docstring 2"
  end
end