# Details

## Nested groups

Given a spec file:

    RSpec.describe "Outer" do
      it "one" do
        expect(1).to eq(1)
      end

      context "inner" do
        it "two" do
          expect(2).to eq(2)
        end

        describe "innermost" do
          it "three" do
            expect(3).to eq(3)
          end
        end
      end
    end

    RSpec.describe "Another" do
      it "four" do
        expect(4).to eq(4)
      end
    end

Each group is a case, and its level says how deep it is.

    stream = run_tapy

    cases = stream.select { |d| d['type'] == 'case' }

    cases.map { |d| [d['label'], d['level']] }  #=> [['Outer', 0], ['inner', 1], ['innermost', 2], ['Another', 0]]

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'case', 'test', 'case', 'test', 'case', 'test', 'final']

## Output from examples

Given a spec file:

    RSpec.describe "Example" do
      it "is noisy" do
        puts "to stdout"
        warn "to stderr"
      end

      it "is quiet" do
      end

      it "is noisy and fails" do
        puts "before failing"
        expect(1).to eq(2)
      end
    end

What an example prints would break the stream. It is captured and
becomes part of the example's record.

    stream = run_tapy
    tests  = tests(stream)

    tests['is noisy']['stdout']  #=> 'to stdout'
    tests['is noisy']['stderr']  #=> 'to stderr'

    tests['is quiet'].key?('stdout')  #=> false
    tests['is quiet'].key?('stderr')  #=> false

    tests['is noisy and fails']['stdout']  #=> 'before failing'

    @stderr  #=> ''

## The seed

When the examples run in random order, the seed is in the `suite`
document.

    stream = run_tapy('--seed', '42')

    stream.first['seed']  #=> 42

Otherwise there is none.

    stream = run_tapy

    stream.first['seed']  #=> nil

## A spec file that can't be loaded

Given a spec file:

    RSpec.describe "Example" do
      it "passes" do
        expect(1).to eq(1)
      end
    end

    raise "can't go on"

What RSpec has to say about it becomes a note, after the `suite`
document that has to begin the stream. (RSpec reports such an error
from version 3.6. Before that it let the error end the run.)

    if Gem.loaded_specs['rspec-core'].version >= Gem::Version.new('3.6')
      stream = run_tapy

      stream.map { |d| d['type'] }.assert == ['suite', 'note', 'final']

      stream[1]['text'].assert.include?("can't go on")

      @status.refute.success?
    end
