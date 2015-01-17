# Release History

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

