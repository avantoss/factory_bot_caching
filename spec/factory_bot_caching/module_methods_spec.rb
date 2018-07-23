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

require 'factory_bot_caching/module_methods'

describe FactoryBotCaching do
  describe '.configuration' do
    it 'returns a singleton Config instance' do
      instance = described_class.configuration
      expect(instance).to be described_class.configuration
      expect(instance).to be_an_instance_of(described_class::Config)
    end
  end

  context 'with mocked configuration' do
    let(:configuration) { described_class::Config.new }

    before do
      # Prevents mutating the global configuration
      allow(described_class).to receive(:configuration).and_return(configuration)
    end

    describe 'enabled?' do
      it 'returns true when caching is enabled' do
        allow(configuration).to receive(:factory_caching_enabled?).and_return(true)
        expect(described_class.enabled?).to be true
      end

      it 'returns true when caching is disabled' do
        allow(configuration).to receive(:factory_caching_enabled?).and_return(false)
        expect(described_class.enabled?).to be false
      end
    end

    describe '#configure' do
      it 'yields the configuration instance to the block' do
        yielded = nil
        described_class.configure do |arg|
          yielded = arg
        end
        expect(yielded).to be configuration
      end

      it 'raises an error when no block given' do
        expect { described_class.configure }.to raise_error(ArgumentError, 'You must supply a block!')
      end
    end

    describe '.without_caching' do
      it 'yields the given block with factory caching disabled' do
        configuration.enable_factory_caching
        described_class.without_caching do
          expect(configuration.factory_caching_enabled?).to be false
        end
      end

      it 're-enables factory caching after executing the block' do
        configuration.enable_factory_caching
        described_class.without_caching do
          nil
        end
        expect(configuration.factory_caching_enabled?).to be true
      end

      it 're-enables factory caching after executing the block even if the block raises' do
        configuration.enable_factory_caching

        expect do
          described_class.without_caching do
            raise ArgumentError
          end
        end.to raise_error(ArgumentError)

        expect(configuration.factory_caching_enabled?).to be true
      end

      it 'leaves factory caching disabled after executing the block if it was already disabled' do
        configuration.disable_factory_caching
        described_class.without_caching do
          expect(configuration.factory_caching_enabled?).to be false
        end
        expect(configuration.factory_caching_enabled?).to be false
      end
    end
  end
end
