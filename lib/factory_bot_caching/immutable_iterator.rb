# The MIT License (MIT)
#
# Copyright (c) 2017-2018 Avant
#
# Author Tim Mertens
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

module FactoryBotCaching
  class ImmutableIterator
    def initialize(enumerable)
      # Make a shallow copy of the collection to ensure mutations to the original array do not affect our iterator:
      @enumerator = enumerable.is_a?(Enumerator) ? enumerable.to_a : enumerable.dup
      @position   = 0
    end

    def until_end
      while(next?)
        yield next_value
      end
    end

    # Advances the position of the iterator to the next value.
    # If a block is given, advances to the next value where the block returns true, or the end of the collection if
    # none match.
    def next(&comparison)
      fast_forward(&comparison) if block_given?
      return next? ? next_value : nil
    end

    def fast_forward(&comparison)
      while(next?)
        return if comparison.call(peek)
        advance_position
      end
    end

    def peek
      enumerator[@position]
    end

    private

    attr_reader :enumerator

    def next?
      @position < enumerator.count
    end

    def advance_position
      @position += 1
    end

    def next_value
      peek
    ensure
      advance_position
    end
  end
end
