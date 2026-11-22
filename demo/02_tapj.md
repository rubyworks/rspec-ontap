# TAP-J

Given a spec file:

    RSpec.describe "Example" do
      it "passes" do
        expect(1).to eq(1)
      end

      it "fails" do
        expect(1).to eq(2)
      end
    end

The `RSpec::TapJ` formatter gives a TAP-J stream: the same records as
TAP-Y, as a JSON document on each line.

    stream = run_tapj

    stream.map { |d| d['type'] }  #=> ['suite', 'case', 'test', 'test', 'final']

    tests = tests(stream)

    tests['passes']['status']            #=> 'pass'
    tests['fails']['status']             #=> 'fail'
    tests['fails']['exception']['file']  #=> './spec/example_spec.rb'
    tests['fails']['exception']['line']  #=> 7

    stream.last['counts']  #=> {'total'=>2, 'pass'=>1, 'fail'=>1, 'error'=>0, 'omit'=>0, 'todo'=>0}

The formatters can also be loaded by requiring `rspec/ontap`.

    stream = run_specs('-r', 'rspec/ontap', '-f', 'RSpec::TapJ').lines

    stream.size  #=> 5
