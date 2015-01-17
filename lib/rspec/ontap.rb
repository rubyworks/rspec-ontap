require 'rspec/core/formatters/base_formatter'

module RSpec
  #module Core
    #module Formatters

  #  
  class TapBaseFormatter < Core::Formatters::BaseFormatter

    # TAP-Y/J Revision
    REVISION = 4

    #
    attr_accessor :example_group_stack

    #
    def initialize(output)
      super(output)
      @example_group_stack = []
    end

    #
    # This method is invoked before any examples are run, right after
    # they have all been collected. This can be useful for special
    # formatters that need to provide progress on feedback (graphical ones)
    #
    # This will only be invoked once, and the next one to be invoked
    # is #example_group_started
    #
    def start(notification)
      # there is a super method for this
      super(notification)

      @start_time = Time.now

      doc = {
        'type'  => 'suite',
        'start' => @start_time.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => notification.count,
        'seed'  => @seed,
        'rev'   => REVISION
      }
      return doc
    end

    #
    # This method is invoked at the beginning of the execution of each example group.
    # +example_group+ is the example_group.
    #
    # The next method to be invoked after this is +example_passed+,
    # +example_pending+, or +example_finished+
    #
    def example_group_started(notification)
      # there is a super method for this
      super(notification)
      doc = {
        'type'    => 'case',
        'subtype' => 'describe',
        'label'   => "#{notification.group.description}",
        'level'   => @example_group_stack.size
      }
      @example_group_stack << example_group
      return doc
    end

    # This method is invoked at the end of the execution of each example group.
    # +example_group+ is the example_group.
    def example_group_finished(notification)
      #super(notification)
      @example_group_stack.pop
    end

    #
    def example_started(notification)
      # set up stdout and stderr to be captured
      reset_output
    end

    #
    def example_passed(notification)
      #super(notification)

      example = notification.example

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

      doc.update(captured_output)
   
      return doc
    end

    #
    def example_pending(notification)
      #super(notification)

      example = notification.example

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

      doc.update(captured_output)

      return doc
    end

    #
    def example_failed(notification)
      #super(notification)

      example = notification.example

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

      doc.update(captured_output)

      return doc
    end

    # This method is invoked after the dumping of examples and failures.
    def dump_summary(summary_notification)
      #super(summary_notification)

      duration      = summary_notification.duration
      example_count = summary_notification.examples.size
      failure_count = summary_notification.failed_examples.size
      pending_count = summary_notification.pending_examples.size

      failed_examples = summary_notification.failed_examples

      error_count = 0

      failed_examples.each do |e|
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

    def seed(notification)
      @seed = notification.seed
    end

    # Add any messages as notes.
    def message(message_notification)
      doc = {
        'type' => 'note',
        'text' => message_notification.message
      }
      return doc
    end

    #
    # NOTE: None of the following are being used. If ever added, be sure
    #       to activate in register calls below.
    #

    # (not used)
    def stop(examples_notification)
      super(examples_notification)
    end

    # (not used)
    def start_dump(null_notification)
    end

    # (not used)
    def dump_pending(examples_notification)
    end

    # (not used)
    def dump_failures(examples_notification)
    end

    # (not used)
    def close(null_notification)
      # there is a super method for this
      super(null_notification)
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

    #
    def reset_output
      @_oldout = $stdout
      @_olderr = $stderr

      @_newout = StringIO.new
      @_newerr = StringIO.new

      $stdout = @_newout
      $stderr = @_newerr
    end

    #
    def captured_output
      stdout = @_newout.string.chomp("\n")
      stderr = @_newerr.string.chomp("\n")

      doc = {}
      doc['stdout'] = stdout unless stdout.empty?
      doc['stderr'] = stderr unless stderr.empty?

      $stdout = @_oldout
      $stderr = @_olderr

      return doc
    end

    #
    def capture_io
      ostdout, ostderr = $stdout, $stderr
      cstdout, cstderr = StringIO.new, StringIO.new
      $stdout, $stderr = cstdout, cstderr

      yield

      return cstdout.string.chomp("\n"), cstderr.string.chomp("\n")
    ensure
      $stdout = ostdout
      $stderr = ostderr
    end

  end

  #
  class TapY < TapBaseFormatter
    ::RSpec::Core::Formatters.register self, 
        :start,
        :example_group_started,
        :example_group_finished,
        :example_started,
        :example_passed,
        :example_failed,
        :example_pending,
        :dump_summary,
        :seed,
        :message,
        #:stop,
        #:start_dump,
        #:dump_pending,
        #:dump_failures,
        :close

    def initialize(*args)
      require 'yaml'
      super(*args)
    end
    def start(*args)
      output.puts super(*args).to_yaml
    end
    def example_group_started(*args)
      output.puts super(*args).to_yaml
    end
    def example_passed(*args)
      output.puts super(*args).to_yaml
    end
    def example_pending(*args)
      output.puts super(*args).to_yaml
    end
    def example_failed(*args)
      output.puts super(*args).to_yaml
    end
    #def dump_summary(duration, example_count, failure_count, pending_count)
    #  output.puts super(duration, example_count, failure_count, pending_count).to_yaml
    #  output.puts "..."
    #end
    def dump_summary(*args)
      output.puts super(*args).to_yaml
      output.puts "..."
    end
  end

  #rspec -f RSpec::TapY spec/*.rb | tapout progress
  class TapJ < TapBaseFormatter
    ::RSpec::Core::Formatters.register self, 
        :start,
        :example_group_started,
        :example_group_finished,
        :example_started,
        :example_passed,
        :example_failed,
        :example_pending,
        :dump_summary,
        :seed,
        :message,
        #:stop,
        #:start_dump,
        #:dump_pending,
        #:dump_failures,
        :close

    def initialize(*args)
      require 'json'
      super(*args)
    end
    def start(*args)
      output.puts super(*args).to_json
    end
    def example_group_started(*args)
      output.puts super(*args).to_json
    end
    def example_passed(*args)
      output.puts super(*args).to_json
    end
    def example_pending(*args)
      output.puts super(*args).to_json
    end
    def example_failed(*args)
      output.puts super(*args).to_json
    end
    def dump_summary(*args)
      output.puts super(*args).to_json
    end
  end

    #end
  #end
end
