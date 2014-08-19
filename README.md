[![Gem Version](https://badge.fury.io/rb/detach.svg)](http://badge.fury.io/rb/detach)

# Detach

A mixin which separates method definitions by argument types, effectively allowing
C++ or Java style overloading.


## Installation

Add this line to your application's Gemfile:

    gem 'detach'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install detach

## Usage

Include the module

    include Detach

Then declare your overloaded methods

    taking['String','Numeric']
    def foo(a,b)
    end
    
    taking['Object']
    def foo(a)
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
