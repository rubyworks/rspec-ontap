require 'tmpdir'
require 'open3'
require 'rbconfig'
require 'yaml'
require 'json'

# Each demo writes a spec file and runs it with the `rspec` command, in
# a process of its own.

LIB = File.expand_path('../../lib', __dir__)

When 'iven a spec file' do |text|
  @source = text
end

# Run the spec file with the given command line options. Returns what
# the run wrote to standard output.
def run_specs(*options)
  rspec = Gem.bin_path('rspec-core', 'rspec')
  Dir.mktmpdir('rspec-ontap') do |dir|
    Dir.mkdir(File.join(dir, 'spec'))
    File.write(File.join(dir, 'spec', 'example_spec.rb'), @source)
    command = [RbConfig.ruby, rspec, "-I#{LIB}", '--no-color', *options]
    @stdout, @stderr, @status = Open3.capture3(*command, :chdir => dir)
  end
  @stdout
end

# Run the spec file and read its output as a TAP-Y stream.
def run_tapy(*options)
  YAML.load_stream(run_specs('-f', 'RSpec::TapY', *options))
end

# Run the spec file and read its output as a TAP-J stream.
def run_tapj(*options)
  run_specs('-f', 'RSpec::TapJ', *options).lines.map { |line| JSON.parse(line) }
end

# The test records of a stream, by label.
def tests(stream)
  stream.select { |d| d['type'] == 'test' }.to_h { |d| [d['label'], d] }
end

# Pipe a stream through Tapout. Returns what Tapout printed.
def tapout(stream, reporter)
  bin = Gem.bin_path('tapout', 'tapout')
  out, _ = Open3.capture2(RbConfig.ruby, bin, reporter, :stdin_data => stream)
  out
end
