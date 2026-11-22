# Release History

## 0.4.0 / 2026-11-22

RSpec On Tap runs on current Ruby and RSpec, and tells skipped examples
from pending ones. It needs Ruby 2.7 or newer and RSpec 3.

Changes:

* Report an example that was skipped (`skip`, `xit`) with the status
  `omit`. One that is pending, or has no body yet, is still a `todo`.
  All four were `todo` before.
* Give the reason an example was skipped or is pending, as the message
  of the record's exception section.
* Report a pending example that passes as a failure, as RSpec does. It
  was reported as an error.
* Report a failed mock expectation as a failure, too.
* Pass on what RSpec says outside of an example, such as an error while
  loading a spec file, as a note. It was dropped.
* Leave out the seed when the examples don't run in random order.
* No longer raise when a failure's backtrace is empty or names a file
  that can't be read.
* Require Tapout 0.5 or newer.
* `RSpec::OnTap::VERSION` gives the version.
* Replace the old packaging (`.index`, `.gemspec`, `Assembly`,
  `MANIFEST`) with a plain `rspec-ontap.gemspec`, and Travis with GitHub
  Actions, testing Ruby 2.7 to 4.0.


## 0.3.1 / 2015-07-17

Changes:

* Fix calls to `relative_path`, which raised NoMethodError for every
  passing and pending example (#2).


## 0.3.0 / 2014-01-17

This is a major overhaul of the formatter to work with RSpec 3+.
It will no longer work with older versions of RSpec! Please use
version 0.2.0 of this plugin if you need that.

Changes:

* Register formmater per new RSpec 3 API.
* Change callback methods to use v3 Notification classes.


## 0.2.0 / 2012-02-01

This release adds support for $stdout and $stderr capturing.

Changes:

* Handle captured stdout and stderr.


## 0.1.0 / 2011-12-13

This is the first release of `RSpec On Tap`, a formatter for RSpec
providing TAP-Y and TAP-J output, which can then be used with
TapOut to produce a variety of formats.

Changes:

* The code was written.

