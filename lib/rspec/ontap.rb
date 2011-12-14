require 'rspec/core/formatters/base_formatter'

module RSpec
  #module Core
    #module Formatters

  #  
  class TapBaseFormatter < Core::Formatters::BaseFormatter

    # TAP-Y/J Revision
    REVISION = 3

    attr_accessor :example_group_stack

    def initialize(output)
      super(output)
      @example_group_stack = []
    end

    # This method is invoked before any examples are run, right after
    # they have all been collected. This can be useful for special
    # formatters that need to provide progress on feedback (graphical ones)
    #
    # This will only be invoked once, and the next one to be invoked
    # is #example_group_started
    def start(example_count)
      super(example_count)

      @start_time = Time.now

      doc = {
        'type'  => 'suite',
        'start' => @start_time.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => example_count,
        'seed'  => @seed,
        'rev'   => REVISION
      }
      return doc
    end

    # This method is invoked at the beginning of the execution of each example group.
    # +example_group+ is the example_group.
    #
    # The next method to be invoked after this is +example_passed+,
    # +example_pending+, or +example_finished+
    def example_group_started(example_group)
      super(example_group) #@example_group = example_group
      doc = {
        'type'    => 'case',
        'subtype' => 'describe',
        'label'   => "#{example_group.description}",
        'level'   => @example_group_stack.size
      }
      @example_group_stack << example_group
      return doc
    end

    # This method is invoked at the end of the execution of each example group.
    # +example_group+ is the example_group.
    def example_group_finished(example_group)
      @example_group_stack.pop
    end

    #
    def example_started(example)
      examples << example
    end

    #
    def example_passed(example)
      super(example)

      file, line = example.location.split(':')
      file = self.class.relative_path(file)
      line = line.to_i

      doc = {
        'type'     => 'test',
        'subtype'  => 'it',
        'status'   => 'pass',
        #'setup': foo instance
        'label'    => "#{example.description}",
        #'expected' => 2
        #'returned' => 2
        'file'     => file,
        'line'     => line,
        'source'   => source(file)[line-1].strip,
        'snippet'  => code_snippet(file, line),
        #'coverage' => {
        #  file: lib/foo.rb
        #  line: 11..13
        #  code: Foo#*
        #}
        'time' => Time.now - @start_time
      }
      return doc
    end

    #
    def example_pending(example)
      super(example)

      file, line = example.location.split(':')
      file = self.class.relative_path(file)
      line = line.to_i

      doc = {
        'type'    => 'test',
        'subtype' => 'it',
        'status'  => 'todo',
        #'setup': foo instance
        'label'   => "#{example.description}",
        'file'    => file,
        'line'    => line,
        'source'  => source(file)[line-1].strip,
        'snippet' => code_snippet(file, line),
        #'coverage' => {
        #  file: lib/foo.rb
        #  line: 11..13
        #  code: Foo#*
        #}
        'time' => Time.now - @start_time
      }
      return doc
    end

    def example_failed(example)
      super(example)

      file, line = example.location.split(':')

      file = self.class.relative_path(file)
      line = line.to_i

      if RSpec::Expectations::ExpectationNotMetError === example.exception
        status = 'fail'
        if md = /expected:\s*(.*?)\n\s*got:\s*(.*?)\s+/.match(example.exception.to_s)
          expected, returned = md[1], md[2]
        else
          expected, returned = nil, nil
        end
      else
        status = 'error'
      end

      backtrace = format_backtrace(example.exception.backtrace, example)

      efile, eline = parse_source_location(backtrace)

      doc = {
        'type'        => 'test',
        'subtype'     => 'it',
        'status'      => status,
        'label'       => "#{example.description}",
        #'setup' => "foo instance",
        'file'    => file,
        'line'    => line,
        'source'  => source(file)[line-1].strip,
        'snippet' => code_snippet(file, line),
        #'coverage' =>
        #{
        #  'file' => lib/foo.rb
        #  'line' => 11..13
        #  'code' => Foo#*
        #}
      }

      if expected or returned
        doc.update(
          'expected' => expected,
          'returned' => returned,
        )
      end

      doc.update(
        'exception' => {
          'message'   => example.exception.to_s.strip,
          'class'     => example.exception.class.name,
          'file'      => efile,
          'line'      => eline,
          'source'    => source(efile)[eline-1].strip,
          'snippet'   => code_snippet(efile, eline),
          'backtrace' => backtrace
        },
        'time' => Time.now - @start_time
      )

      return doc
    end

    # @todo Is this a note?
    def message(message)
    end

    #def stop
    #end

    # This method is invoked after the dumping of examples and failures.
    def dump_summary(duration, example_count, failure_count, pending_count)
      super(duration, example_count, failure_count, pending_count)

      error_count = 0

      @failed_examples.each do |e|
        if RSpec::Expectations::ExpectationNotMetError === e.exception
          #failure_count += 1
        else
          failure_count -= 1
          error_count += 1
        end
      end

      passing_count = example_count - failure_count - error_count - pending_count

      doc = {
        'type' => 'final',
        'time' => duration,
        'counts' => {
          'total' => example_count,
          'pass'  => passing_count,
          'fail'  => failure_count,
          'error' => error_count,
          'omit'  => 0,
          'todo'  => pending_count
        }
      }
      return doc
    end

    # This gets invoked after the summary if option is set to do so.
    #def dump_pending
    #end

    def seed(number)
      @seed = number
    end

  private

    # Returns a String of source code.
    def code_snippet(file, line)
      s = []
      if File.file?(file)
        source = source(file)
        radius = 2 # TODO: make customizable (number of surrounding lines to show)
        region = [line - radius, 1].max ..
                 [line + radius, source.length].min

        s = region.map do |n|
          {n => source[n-1].chomp}
        end
      end
      return s
    end

    # Cache source file text. This is only used if the TAP-Y stream
    # doesn not provide a snippet and the test file is locatable.
    def source(file)
      @_source_cache ||= {}
      @_source_cache[file] ||= (
        File.readlines(file)
      )
    end

    # Parse source location from caller, caller[0] or an Exception object.
    def parse_source_location(caller)
      case caller
      when Exception
        trace  = caller.backtrace #.reject{ |bt| bt =~ INTERNALS }
        caller = trace.first
      when Array
        caller = caller.first
      end
      caller =~ /(.+?):(\d+(?=:|\z))/ or return ""
      source_file, source_line = $1, $2.to_i
      return source_file, source_line
    end

  end

  #
  class TapY < TapBaseFormatter
    def initialize(*whatever)
      require 'yaml'
      super(*whatever)
    end
    def start(example_count)
      output.puts super(example_count).to_yaml
    end
    def example_group_started(example_group)
      output.puts super(example_group).to_yaml
    end
    def example_passed(example)
      output.puts super(example).to_yaml
    end
    def example_pending(example)
      output.puts super(example).to_yaml
    end
    def example_failed(example)
      output.puts super(example).to_yaml
    end
    def dump_summary(duration, example_count, failure_count, pending_count)
      output.puts super(duration, example_count, failure_count, pending_count).to_yaml
      output.puts "..."
    end
  end

  #
  class TapJ < TapBaseFormatter
    def initialize(*whatever)
      require 'json'
      super(*whatever)
    end
    def start(example_count)
      output.puts super(example_count).to_json
    end
    def example_group_started(example_group)
      output.puts super(example_group).to_json
    end
    def example_passed(example)
      output.puts super(example).to_json
    end
    def example_pending(example)
      output.puts super(example).to_json
    end
    def example_failed(example)
      output.puts super(example).to_json
    end
    def dump_summary(duration, example_count, failure_count, pending_count)
      output.puts super(duration, example_count, failure_count, pending_count).to_json
    end
  end

    #end
  #end
end
