if RUBY_VERSION < '1.9'
  require File.dirname(__FILE__) + '/tap'
else
  require_relative 'tap'
end
