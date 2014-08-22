require 'test/unit'
require 'detach'

class TestDetach < Test::Unit::TestCase

	def testBasicTypes
		assert_equal "String hello", Foo.new.foo('hello')
		assert_equal "Integer 42", Foo.new.foo(42)
		assert_equal "Strings helloworld", Foo.new.foo('hello', 'world')
		assert_equal "Integers 42", Foo.new.foo(40, 2)
		assert_equal "Floats 4.7", Foo.new.foo(3.1, 1.6)
		assert_equal "Numbers 4.7", Foo.new.foo(3, 1.7)
	end

	def testNoArgs
		assert_equal "Nonce", Foo.new.foo
	end

	def testLists
		assert_equal "Object List [\"one\", 2, 3.0, \"4\"]", Foo.new.foo('one', 2, 3.0, '4')
		assert_equal "String List [\"one\", \"two\", \"three\", \"four\"]", Foo.new.foo('one', 'two', 'three', 'four')
	end

	def testMixedLists
		assert_equal "Int-String List-String 1 [] guy", Foo.new.foo(1, 'guy')
		assert_equal "Int-String List-String 1 [\"is\", \"the\", \"lonliest\"] number", Foo.new.foo(1, 'is', 'the', 'lonliest', 'number')
	end

	def testOptional
		assert_equal "Int-String-Int 7 ate 9", Foo.new.foo(7, 'ate', 9)
		assert_equal "Int-String-Int 42 < 99", Foo.new.foo('<', 99)
	end

	def testCustomObject
		assert_equal "P::M 42", Foo.new.foo(P::M.new)
	end

	def testMethodNamedTaking
		assert_equal "hello", Bar.new.taking("hello")
	end

	def testConstructor
		assert_equal "hello world", Wow.new("hello", "world").to_s
		assert_equal "11", Wow.new(5, 6).to_s
	end

	def testDefinitionOrder
		assert_equal "Nonce", Junk.new.foo
		assert_equal "String one", Junk.new.foo('one')
		assert_equal "String List [\"one\", \"two\", \"three\", \"four\"]", Junk.new.foo('one', 'two', 'three', 'four')
	end


	#
	#  helper definitions
	#

	module P
		class M
			def wow
				42
			end
		end
	end

	class Foo
		include Detach

		taking[String, String]
		def foo(a, b)
			"Strings #{a + b}"
		end

		taking[Integer, Integer]
		def foo(a, b)
			"Integers #{a + b}"
		end

		taking[Float, Float]
		def foo(a, b)
			"Floats #{a + b}"
		end

		taking[Numeric, Numeric]
		def foo(a, b)
			"Numbers #{a + b}"
		end

		taking[String]
		def foo(a)
			"String #{a}"
		end

		taking[Integer]
		def foo(a)
			"Integer #{a}"
		end

		taking[]
		def foo
			"Nonce"
		end

		taking[Object]
		def foo(*a)
			"Object List #{a}"
		end

		taking[String]
		def foo(*a)
			"String List #{a}"
		end

		taking[Integer, String, String]
		def foo(a, *b, c)
			"Int-String List-String #{a} #{b} #{c}"
		end

		taking[Integer, String, Integer]
		def foo(a=42, b, c)
			"Int-String-Int #{a} #{b} #{c}"
		end

		taking[P::M]
		def foo(m)
			"P::M #{m.wow}"
		end
	end

	class Bar
		include Detach

		taking[String]
		def taking(s)
			@s = s
		end
	end

	class Wow
		include Detach

		taking[String,String]
		def initialize(a,b)
			@s = "#{a} #{b}"
		end

		taking[Integer,Integer]
		def initialize(a,b)
			@s = a + b
		end

		def to_s
			@s.to_s
		end
	end

	class Junk
		include Detach

		taking[Object]
		def foo(*a)
			"Object List #{a}"
		end

		taking[String]
		def foo(*a)
			"String List #{a}"
		end

		taking[]
		def foo
			"Nonce"
		end

		taking[String]
		def foo(a)
			"String #{a}"
		end

	end

end


