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

require 'factory_bot_caching/immutable_iterator'

describe FactoryBotCaching::ImmutableIterator do
  describe '#until_end' do
    let(:enumerator) { described_class.new([1,2,3,4,5]) }

    it 'iterates the block until there are no values left to yield' do
      values = []
      enumerator.until_end do |value|
        values << value
      end
      expect(values).to eq [1,2,3,4,5]
    end

    it 'does nothing when the iterator has already reached the end' do
      spy1, spy2 = spy, spy

      enumerator.until_end do |value|
        spy1.investigate
      end
      expect(spy1).to have_received(:investigate).exactly(5).times

      enumerator.until_end do |value|
        spy2.investigate
      end
      expect(spy2).not_to have_received(:investigate)
    end

    it 'continues from its previous position when broken mid loop' do
      values = []

      enumerator.until_end do |value|
        values << value
        break if value > 2
      end
      expect(values).to eq [1, 2, 3]

      enumerator.until_end do |value|
        values << value
      end
      expect(values).to eq [1, 2, 3, 4, 5]
    end

    it 'is not affected by mutations of the original array' do
      original_values = [1,2,3,4,5]
      values = []

      enumerator = described_class.new(original_values)

      enumerator.until_end do |value|
        values << value
        break if value > 2
      end
      expect(values).to eq [1, 2, 3]

      original_values << 6
      original_values.delete(3)

      enumerator.until_end do |value|
        values << value
      end
      expect(values).to eq [1, 2, 3, 4, 5]
    end
  end

  describe '#next' do
    it 'advances to and returns the next value when no block supplied' do
      enumerator = described_class.new([1,2,3])
      expect(enumerator.next).to eq 1
      expect(enumerator.next).to eq 2
      expect(enumerator.next).to eq 3
      expect(enumerator.next).to be_nil
    end

    it 'advances to and returns the next value for which the supplied block returns true' do
      enumerator = described_class.new([1,2,3,4,5])
      value = enumerator.next { |v| v > 3 }
      expect(value).to eq 4
      expect(enumerator.peek).to eq 5
    end

    it 'returns nil and advances to the end of the iterator when no value matches' do
      enumerator = described_class.new([1,2,3,4,5])
      value = enumerator.next { |v| v > 5 }
      expect(value).to be_nil
      expect(enumerator.peek).to be_nil
    end

    it 'does nothing for empty collections' do
      enumerator = described_class.new([])
      enumerator.next { |v| v > 3 }
      expect(enumerator.next).to be_nil
    end
  end

  describe '#peek' do
    it 'returns the next value without incrementing the position' do
      enumerator = described_class.new([1,2,3])
      expect(enumerator.peek).to eq(1)
      enumerator.next
      expect(enumerator.peek).to eq(2)
      enumerator.next
      expect(enumerator.peek).to eq(3)
      enumerator.next
      expect(enumerator.peek).to be_nil
    end
  end

  describe '#fast_forward' do
    it 'does nothing for empty collections' do
      enumerator = described_class.new([])
      enumerator.next { |v| v > 3 }
      expect(enumerator.next).to be_nil
    end

    it 'advances iterator to and peeks the next value for which the supplied block returns true' do
      enumerator = described_class.new([1,2,3,4,5])
      value = enumerator.next { |v| v > 3 }
      expect(value).to eq 4
      expect(enumerator.peek).to eq 5
    end

    it 'returns nil and advances to the end of the iterator when no value matches' do
      enumerator = described_class.new([1,2,3,4,5])
      value = enumerator.next { |v| v > 5 }
      expect(value).to be_nil
      expect(enumerator.peek).to be_nil
    end
  end
end
