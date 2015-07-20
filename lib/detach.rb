# The Detach mixin provides method dispatch according to argument types.
# Method definitions are separated by name and signatue, allowing for
# C++ or Java style overloading.
#
# Example:
#   class Bar
#     include Detach
#     taking['String','String']
#     def foo(a,b)
#       a.upcase + b.upcase
#     end
#     taking['Integer','Integer']
#     def foo(a=42,b)
#       a * b
#     end
#     taking['Object','String']
#     def foo(a,*b)
#       b.map {|s| s.upcase + a.to_s}.join
#     end
#   end
module Detach
	# Extends the base class with the module Detach::Types.
	def self.included(base)
		base.extend(Types)
	end
	# Provides run-time method lookup according to the types of the args.
	#
	# All methods matching the name are scored according to both arity and type.
	# Varargs and default values are interpolated with actual values. Predefined classes
	# are compared to actual classes using equality and inheritence checks.
	def method_missing(name, *args, &block)
		obj_method_missing = -> {
			BasicObject.instance_method(:method_missing).bind(self).call(name, *args, &block)
		}

		# some early returns are necessary when Detach has been mixed into
		# the class of object 'main'
		case name
		when :to_ary
			return obj_method_missing.call
		when :taking
			return Types.instance_method(:taking).bind(self.class).call if self.class == Object
		end

		(score,best) = (public_methods+protected_methods+private_methods).grep(/^#{Regexp.escape(name)}\(/).collect {|candidate|
			# extract paramters
			params = /\((.*)\)/.match(candidate.to_s)[1].scan(/(\w+)-([\w:\)]+)/).collect {|s,t|
				[s.to_sym, t.split(/::/).inject(Kernel) {|m,c| m = m.const_get(c)}]
			}
			# form the list of all required argument classes
			ctypes = params.values_at(*params.each_index.select {|i| params[i].first == :req}).map(&:last)
			nreq = ctypes.size

			# NOTE: ruby only allows a single *args, or a list of a=1, b=2--not both together--
			# only one of the following will execute

			# (A) insert any optional argument classes for as many extra are present
			params.each_index.select {|i| params[i].first == :opt}.each {|i|
				ctypes.insert(i, params[i].last) if args.size > ctypes.size
			}
			# (B) insert the remaining arguments by exploding the appropriate class by the number extra
			params.each_index.select {|i| params[i].first == :rest}.each {|i|
				ctypes.insert(i, *([params[i].last] * (args.size - ctypes.size))) if args.size > ctypes.size
			}

			# now score the given args by comparing their actual classes to the predefined classes
			if args.empty? and ctypes.empty?
				score = 1
			elsif ctypes.size == args.size
				score = args.map(&:class).zip(ctypes).inject(0) {|s,t| 
					# apply each class comparison and require nonzero matches
					if s
						if t[0].ancestors.include?(t[1])
							s += t[1].ancestors.size
						else
							s = nil
						end
					end

				} || 0
			else
				score = 0
			end

			score += (1 + nreq) if args.size == params.size

			[ score, candidate ]

		}.max {|a,b| a[0] <=> b[0]}

		(not score or score == 0) ? obj_method_missing.call : method(best)[*args, &block]
	end

	# The Detach::Types module is inserted as a parent of the class which includes the
	# Detach mixin. This module handles inspection and aliasing of instance methods
	# as they are added.
	#
	# Detach::Types does not need to be extended directly.
	module Types
		# Decorator method for defining argument signature.
		#
		# Example:
		#   taking['String']
		#   def foo(a)
		#   end
		def taking
			self
		end
		# Provides list of type names to decorator.
		def [](*types)
			@@types = types.flatten
		end
		# Provides load-time method aliasing.
		#
		# All methods added to a class which are decorated as taking specified types
		# are aliased in a form known and searched at run-time.
		def method_added(name)
            begin
                @@types     # catch uninitialized @@types here to enable function without taking-prefix
            rescue
                return
            end
			return unless @@types

			# query the parameter info for the method just added
			p = instance_method(name).parameters.map &:first
			raise ArgumentError.new('type and parameter mismatch') unless p.size == @@types.size

			# encode our defined types with parameter info into a new name and remove the original
			n = (name.to_s + '(' + p.zip(@@types).collect {|p,t| "#{p}-#{t}" }.join(',') + ')').to_sym
			@@types = nil

			alias_method n, name unless method_defined?(n)
			define_method(name) {|*args, &block| method_missing(name, *args, &block)}
		end
	end
end

