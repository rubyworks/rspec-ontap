# Tapout

The stream is for Tapout, which renders it in a format of your choice.

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

      it "is skipped" do
        skip "not today"
      end

      it "is yet to be written"
    end

Tapout reads the TAP-Y stream.

    out = tapout(run_specs('-f', 'RSpec::TapY'), 'tap')

    out.assert.include?('1..5')

    out.assert =~ /^ok 1 - passes$/
    out.assert =~ /^not ok 2 - fails$/
    out.assert =~ /^not ok 3 - errors$/
    out.assert =~ /^ok 4 - is skipped # SKIP not today$/
    out.assert =~ /^not ok 5 - is yet to be written # TODO Not yet implemented$/

And the TAP-J stream.

    out = tapout(run_specs('-f', 'RSpec::TapJ'), 'tap')

    out.assert =~ /^ok 1 - passes$/
    out.assert =~ /^not ok 2 - fails$/
    out.assert =~ /^ok 4 - is skipped # SKIP not today$/
