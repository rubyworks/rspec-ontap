# Skipped and pending examples

Given a spec file:

    RSpec.describe "Example" do
      it "is skipped" do
        skip "not on this machine"
      end

      xit "is crossed out" do
        expect(1).to eq(2)
      end

      it "is pending" do
        pending "waiting on a fix"
        expect(1).to eq(2)
      end

      it "is yet to be written"

      it "was pending" do
        pending "waiting on a fix"
        expect(1).to eq(1)
      end
    end

RSpec calls all of the first four pending. TAP-Y/J tells them apart.

    stream = run_tapy
    tests  = tests(stream)

An example that was skipped is omitted, with the reason.

    tests['is skipped']['status']                #=> 'omit'
    tests['is skipped']['exception']['message']  #=> 'not on this machine'

    tests['is crossed out']['status']                #=> 'omit'
    tests['is crossed out']['exception']['message']  #=> 'Temporarily skipped with xit'

An example that is pending, or has no body yet, is still to be done.

    tests['is pending']['status']                #=> 'todo'
    tests['is pending']['exception']['message']  #=> 'waiting on a fix'

    tests['is yet to be written']['status']                #=> 'todo'
    tests['is yet to be written']['exception']['message']  #=> 'Not yet implemented'

A pending example that passes is a failure, as it is to RSpec, and not
an error.

    tests['was pending']['status']  #=> 'fail'

    tests['was pending']['exception']['message'].assert.include?('it passed')

The counts agree.

    stream.last['counts']  #=> {'total'=>5, 'pass'=>0, 'fail'=>1, 'error'=>0, 'omit'=>2, 'todo'=>2}
