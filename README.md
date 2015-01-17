# RSpec On Tap

[Homepage](http://rubyworks.github.com/rspec-ontap) |
[Source Code](http://github.com/rubyworks/rspec-ontap) |
[Report Issue](http://github.com/rubyworks/rspec-ontap/issues)


## Description

**RSpec On Tap** is a TAP-Y/J formatter for RSpec.

The latest version works with **RSpec 3+ only**.

You can learn more about TAP-Y/J [here](https://github.com/rubyworks/tapout).


## Usage

Usage is simply a matter of requiring the plugin and passing the name of the
format class to the `rspec` command via the `-f` option.

    $ rspec -r rspec/ontap -f RSpec::TapY spec/*.rb

This can be shortened to just:

    $ rspec -f RSpec::TapY spec/*.rb

This works because RSpec will automatically require a related path -- in this
case `rspec/tap_y` -- if the class if initially undefined. The library file
`rspec/tap_y` itself simply requires `rspec/ontap` (the same is true for
`rspec/tap_j`).

With TAP-Y output in hand, the `tapout` tool can then be used to produce a
variety of other output formats. First, make sure Tapout is installed:

    $ gem install tapout

Then, for example:

    $ rspec -f RSpec::TapY spec/*.rb | tapout progress

See the [TapOut project](http://rubyworks.github.com/tapout) for more information.



## Installation

Installation follows the usual pattern:

    $ gem install rspec-ontap

Or using your Gemfile, add something like:

    group :test do
      gem "rspec-ontap", :require => false
    end


## Copyrights

Copyright (c) 2011 Rubyworks. All Rights Reserved.

RSpecOnTap is distributable in accordance with the *FreeBSD* license.

See LICENSE.txt for details.

