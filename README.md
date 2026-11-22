# RSpec On Tap

[Documentation](https://rubydoc.info/gems/rspec-ontap) |
[Report Issue](https://github.com/rubyworks/rspec-ontap/issues) |
[Source Code](https://github.com/rubyworks/rspec-ontap)

[![CI](https://github.com/rubyworks/rspec-ontap/actions/workflows/ci.yml/badge.svg)](https://github.com/rubyworks/rspec-ontap/actions/workflows/ci.yml)
[![Gem Version](https://badge.fury.io/rb/rspec-ontap.svg)](https://badge.fury.io/rb/rspec-ontap)


## Description

**RSpec On Tap** is a pair of formatters for [RSpec](https://rspec.info)
that report in TAP-Y or TAP-J. Those are the formats that
[Tapout](https://github.com/rubyworks/tapout) reads, so with RSpec On Tap
a suite of specs can be shown in any of Tapout's report formats.

    $ rspec -f RSpec::TapY | tapout progress

It works with RSpec 3, on Ruby 2.7 and newer.


## Installation

    $ gem install rspec-ontap

Or in a Gemfile:

    group :test do
      gem "rspec-ontap", :require => false
    end

Tapout is installed along with it.


## Usage

Give the `rspec` command the name of the formatter with its `-f` option:
`RSpec::TapY` for TAP-Y, or `RSpec::TapJ` for TAP-J.

    $ rspec -f RSpec::TapY

Nothing has to be required. When RSpec doesn't know a formatter, it
requires a file named after it, here `rspec/tap_y`, and that loads the
formatters. If you'd rather be explicit:

    $ rspec -r rspec/ontap -f RSpec::TapY

The output is a TAP-Y stream, which isn't meant to be read as it is.
Pipe it to `tapout`, with the name of the report you want:

    $ rspec -f RSpec::TapY | tapout progress

`tapout --help` lists the reports.

### What is reported

* Each example group is a case, nested as the groups are, and each
  example a test.
* A failure or error comes with its message, the file and line, the
  lines of source around it, and RSpec's backtrace. An expectation that
  wasn't met is a failure; anything else raised is an error.
* An example that was skipped, with `skip` or `xit`, is reported as
  omitted. One that is pending, or has no body yet, is reported as still
  to be done. Both give the reason.
* What an example prints to `$stdout` and `$stderr` is captured and
  reported with the example, since it would otherwise break the stream.
* Anything RSpec says outside of an example, such as an error while
  loading a spec file, is passed on as a note.


## Copyrights

Copyright (c) 2011 Rubyworks. All Rights Reserved.

RSpec On Tap is distributable in accordance with the *BSD-2-Clause*
license.

See LICENSE.txt for details.
