# TAP-Y

Given a spec file:

    RSpec.describe "Example" do
      it "passes" do
        expect(1).to eq(1)
      end

      it "fails" do
        expect(1).to eq(2)
      end

      it "errors" do
        raise NameError, "oops"
      end
    end

Running it with the `RSpec::TapY` formatter gives a TAP-Y stream. RSpec
finds the formatter by its name, so nothing has to be required.

    stream = run_tapy

There are six documents in it.

    stream.size  #=> 6

The first is the `suite`, with the number of examples.

    stream.first['type']   #=> 'suite'
    stream.first['count']  #=> 3
    stream.first['rev']    #=> 4

The second is a `case`, for the example group.

    stream[1]['type']     #=> 'case'
    stream[1]['subtype']  #=> 'describe'
    stream[1]['label']    #=> 'Example'
    stream[1]['level']    #=> 0

The next three are the examples.

    tests = tests(stream)

    tests.keys  #=> ['passes', 'fails', 'errors']

Each says where it is in the spec file.

    passing = tests['passes']

    passing['status']   #=> 'pass'
    passing['subtype']  #=> 'it'
    passing['file']     #=> './spec/example_spec.rb'
    passing['line']     #=> 2
    passing['source']   #=> 'it "passes" do'

    passing.key?('exception')  #=> false

An expectation that isn't met is a failure. It says what was expected
and what came back, and where.

    failing = tests['fails']

    failing['status']    #=> 'fail'
    failing['expected']  #=> '2'
    failing['returned']  #=> '1'

    failing['exception']['class']   #=> 'RSpec::Expectations::ExpectationNotMetError'
    failing['exception']['file']    #=> './spec/example_spec.rb'
    failing['exception']['line']    #=> 7
    failing['exception']['source']  #=> 'expect(1).to eq(2)'

    failing['exception']['message'].assert.include?('expected: 2')

It comes with the lines around the failure.

    failing['exception']['snippet'].map { |line| line.keys.first }  #=> [5, 6, 7, 8, 9]
    failing['exception']['snippet'][2][7]  #=> '    expect(1).to eq(2)'

Anything else raised is an error.

    erring = tests['errors']

    erring['status']                #=> 'error'
    erring['exception']['class']    #=> 'NameError'
    erring['exception']['message']  #=> 'oops'
    erring['exception']['line']     #=> 11

    erring['exception']['backtrace'].first.assert.start_with?('./spec/example_spec.rb:11')

The last document is the `final` one, with the counts.

    stream.last['type']    #=> 'final'
    stream.last['counts']  #=> {'total'=>3, 'pass'=>1, 'fail'=>1, 'error'=>1, 'omit'=>0, 'todo'=>0}

The stream ends with the YAML end-of-document marker.

    @stdout.lines.last  #=> "...\n"

Nothing else is written, and the exit status still tells of the
failures.

    @stderr  #=> ''
    @status.success?  #=> false
