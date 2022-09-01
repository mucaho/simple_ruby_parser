# frozen_string_literal: true

require "rspec"
require "stringio"
require_relative "../../lib/parser/impl"

RSpec.shared_examples "a process" do |process_subject|
  subject(:process) { process_subject }

  let(:source) do
    original = []
    spy = object_spy(StringIO.new, "source")

    allow(spy)
      .to receive(:each_line)
      .and_invoke(original.method(:each))

    { original:, spy: }
  end
  let(:destination) do
    original = []
    spy = object_spy(StringIO.new, "destination")

    allow(spy)
      .to receive(:puts)
      .and_invoke(original.method(:push))

    { original:, spy: }
  end
  let(:transform) do
    original = Parser::Domain::Pipe
    spy = object_spy(original, "transform")

    allow(spy)
      .to receive(:to_proc)
      .and_invoke(original.method(:to_proc))

    { original:, spy: }
  end

  it "has a process! method" do
    expect(process).to respond_to(:process!)
  end

  context "when processing data from source to destination" do
    context "if called with invalid inputs" do
      throws = "then it throws an error"

      it "#{throws} given no input" do
        expect { process.process! }.to raise_error(ArgumentError)
      end

      it "#{throws} given too much input" do
        expect { process.process!(nil, nil, nil, nil) }.to raise_error(ArgumentError)
      end

      it "#{throws} given invalid input" do
        expect { process.transform(nil, nil, nil) }.to raise_error(NoMethodError)
      end
    end

    context "if called with valid inputs" do
      it "then it completes successfully" do
        expect { process.process!(source[:spy], destination[:spy], transform[:spy]) }
          .not_to raise_error
      end
    end

    context "if it completes successfully" do
      it "then it reads an empty input and does nothing", :aggregate_failures do
        process.process!(source[:spy], destination[:spy], transform[:spy])

        expect(source[:spy]).to have_received(:each_line).once
        expect(destination[:spy]).to have_received(:puts).exactly(0).times

        expect(destination[:original]).to eq(source[:original])
      end

      it "then it passes a non-empty input back to output", :aggregate_failures do
        source[:original].push(0)

        process.process!(source[:spy], destination[:spy], transform[:spy])

        expect(source[:spy]).to have_received(:each_line).once
        expect(destination[:spy]).to have_received(:puts).once

        expect(destination[:original]).to eq(source[:original])
      end

      it "then it passes two lines of input back to output", :aggregate_failures do
        source[:original].push(0, 1)

        process.process!(source[:spy], destination[:spy], transform[:spy])

        expect(source[:spy]).to have_received(:each_line).once
        expect(destination[:spy]).to have_received(:puts).twice

        expect(destination[:original]).to eq(source[:original])
      end
    end
  end
end
