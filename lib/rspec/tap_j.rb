if RUBY_VERSION < '1.9'
  require File.dirname(__FILE__) + '/ontap'
else
  require_relative 'ontap'
end
