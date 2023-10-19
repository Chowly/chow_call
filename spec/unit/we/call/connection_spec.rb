require "spec_helper"

RSpec.describe Chow::Call::Connection do
  describe '#initialize' do
    context 'when host is missing' do
      it 'raises ArgumentError' do
        expect { subject.new }.to raise_error(ArgumentError)
      end
    end

    context 'when app is missing' do
      subject { described_class.new(host: 'http://foo.com') }

      it 'raises Chow::Call::Connection::MissingApp' do
        expect { subject }.to raise_error(Chow::Call::Connection::MissingApp)
      end
    end

    context 'when timeout is missing' do
      subject { described_class.new(host: 'http://foo.com', app: 'foo', env: 'test') }

      it 'raises Chow::Call::Connection::MissingTimeout' do
        expect { subject }.to raise_error(Chow::Call::Connection::MissingTimeout)
      end
    end

    context 'when open_timeout is nilled somehow' do
      subject { described_class.new(host: 'http://foo.com', app: 'foo', env: 'test', timeout: 5, open_timeout: nil) }

      it 'raises Chow::Call::Connection::MissingOpenTimeout' do
        expect { subject }.to raise_error(Chow::Call::Connection::MissingOpenTimeout)
      end
    end

    context 'when all arguments are set other than env' do
      subject { described_class.new(host: 'http://foo.com', app: 'pokedex', timeout: 5) }

      context 'and it is guessable' do
        before { allow_any_instance_of(described_class).to receive(:guess_env) { 'test' } }

        it { is_expected.to be }
      end

      context 'and it is NOT guessable' do
        before { allow_any_instance_of(described_class).to receive(:guess_env) { nil } }

        it 'raises Chow::Call::Connection::MissingEnv' do
          expect { subject }.to raise_error(Chow::Call::Connection::MissingEnv)
        end
      end
    end
  end

  context 'when valid arguments are provided' do
    let(:valid_arguments) { { host: 'http://foo.com', app: 'pokedex', env: 'test', timeout: 5 } }

    subject { described_class.new(**valid_arguments) }

    it { is_expected.to be }

    it 'contains User-Agent header' do
      expect(subject.headers['User-Agent']).to eql('pokedex')
    end

    it 'contains X-App-Name header' do
      expect(subject.headers['X-App-Name']).to eql('pokedex')
    end

    it 'contains X-App-Env header' do
      expect(subject.headers['X-App-Env']).to eql('test')
    end

    it 'contains timeout option' do
      expect(subject.options[:timeout]).to eql(valid_arguments[:timeout])
    end

    it 'contains open_timeout option' do
      expect(subject.options[:open_timeout]).to eql(described_class::OPEN_TIMEOUT)
    end

    context 'when open_timeout is passed' do
      let(:valid_arguments_with_open_timeout) { valid_arguments.merge(open_timeout: 2) }

      subject { described_class.new(**valid_arguments_with_open_timeout) }

      it 'contains open_timeout option' do
        expect(subject.options[:open_timeout]).to eql(valid_arguments_with_open_timeout[:open_timeout])
      end
    end

    context 'when app needs to be guessed' do
      before do
        allow(Rails).to receive(:application).and_return(app_class.new)
      end

      let(:valid_arguments_without_app) { valid_arguments.tap { |h| h.delete(:app) } }
      let(:app_class) { stub_const('WeCallTest::Application', Class.new) }

      subject { described_class.new(**valid_arguments_without_app) }

      it 'contains X-App-Name header' do
        expect(subject.headers['X-App-Name']).to eql('we-call-test')
      end

      context 'when app has only one segment' do
        let(:app_class) { stub_const('Test::Application', Class.new) }

        it 'contains X-App-Name header' do
          expect(subject.headers['X-App-Name']).to eql('test')
        end
      end
    end

    context 'with custom block' do
      subject do
        described_class.new(**valid_arguments) do |faraday|
          faraday.headers['Foo'] = 'bar'
        end
      end

      it 'sets custom headers' do
        expect(subject.headers).to include('Foo' => 'bar')
      end
    end
  end
end
