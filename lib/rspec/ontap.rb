require 'rspec/core'
require 'rspec/core/formatters/base_formatter'
require 'rspec/ontap/version'
require 'stringio'

module RSpec

  # Base class of the TAP-Y and TAP-J formatters. It turns RSpec's
  # notifications into the records of a TAP-Y/J stream; the subclasses
  # write them out.
  #
  # While an example runs, `$stdout` and `$stderr` are captured, so that
  # what it prints becomes part of its record instead of breaking the
  # stream.
  class TapBaseFormatter < Core::Formatters::BaseFormatter

    # TAP-Y/J revision.
    REVISION = 4

    # Number of lines of source to show on each side of a line.
    SNIPPET_RADIUS = 2

    # The notifications the formatters ask RSpec for.
    NOTIFICATIONS = [
      :start,
      :example_group_started,
      :example_group_finished,
      :example_started,
      :example_passed,
      :example_failed,
      :example_pending,
      :message,
      :dump_summary,
      :close
    ]

    def initialize(output)
      super(output)
      # Tapout reads from a pipe, so nothing should wait in a buffer.
      output.sync = true if output.respond_to?(:sync=)
      @group_level  = 0
      @source_cache = {}
      @omit_count   = 0
      @early_notes  = []
    end

    # Invoked once, before any example runs.
    def start(notification)
      super
      @start_time = Time.now
      @seed = configuration.seed if configuration.seed_used?
      emit(
        'type'  => 'suite',
        'start' => @start_time.strftime('%Y-%m-%d %H:%M:%S'),
        'count' => notification.count,
        'seed'  => @seed,
        'rev'   => REVISION
      )
      @early_notes.each { |note| emit note }
      @early_notes = nil
    end

    # Invoked at the start of each example group.
    def example_group_started(notification)
      super
      emit(
        'type'    => 'case',
        'subtype' => 'describe',
        'label'   => notification.group.description.to_s,
        'level'   => @group_level
      )
      @group_level += 1
    end

    # Invoked at the end of each example group.
    def example_group_finished(notification)
      @group_level -= 1
    end

    # Invoked before each example. Starts capturing its output.
    def example_started(notification)
      capture_output
    end

    #
    def example_passed(notification)
      emit test_record(notification.example, 'pass')
    end

    # Invoked for an example that was skipped or is pending.
    #
    # An example that was skipped (`skip`, `xit`) is an `omit` in
    # TAP-Y/J. One that is pending, or has no body yet, is a `todo`.
    def example_pending(notification)
      example = notification.example
      reason  = example.execution_result.pending_message.to_s

      if example.skipped? && reason != Core::Pending::NOT_YET_IMPLEMENTED
        status = 'omit'
        @omit_count += 1
      else
        status = 'todo'
      end

      record = test_record(example, status)
      record['exception'] = { 'message' => reason } unless reason.empty?
      emit record
    end

    #
    def example_failed(notification)
      example   = notification.example
      exception = example.exception
      record    = test_record(example, failure?(exception) ? 'fail' : 'error')

      if md = /expected:\s*(.*?)\n\s*got:\s*(.*?)\s+/.match(exception.to_s)
        record['expected'] = md[1]
        record['returned'] = md[2]
      end

      record['exception'] = exception_record(example, exception)
      emit record
    end

    # Invoked for anything RSpec has to say outside of an example, such
    # as an error while loading a spec file. It becomes a note.
    def message(notification)
      text = notification.message.to_s.strip
      return if text.empty?
      note = { 'type' => 'note', 'text' => text }
      # The stream has to begin with the suite, so a note that comes
      # before it waits.
      @early_notes ? @early_notes << note : emit(note)
    end

    # Invoked when all examples have run.
    def dump_summary(summary)
      total    = summary.examples.size
      failed   = summary.failed_examples
      failures = failed.count { |example| failure?(example.exception) }
      errors   = failed.size - failures
      pending  = summary.pending_examples.size

      emit(
        'type'   => 'final',
        'time'   => summary.duration,
        'counts' => {
          'total' => total,
          'pass'  => total - failed.size - pending,
          'fail'  => failures,
          'error' => errors,
          'omit'  => @omit_count,
          'todo'  => pending - @omit_count
        }
      )
      finish
    end

    # Invoked last. Makes sure the real output streams are back.
    def close(notification)
      release_output
      super
    end

  private

    # Write a record to the stream. Subclasses define this.
    def emit(record)
      raise NotImplementedError
    end

    # Write whatever ends the stream.
    def finish
    end

    # What every test record has: where the example is and what it
    # printed.
    def test_record(example, status)
      record = {
        'type'    => 'test',
        'subtype' => 'it',
        'status'  => status,
        'label'   => example.description.to_s
      }

      file, line = split_location(example.location)
      if file
        record['file'] = file
        record['line'] = line
        add_source(record, file, line)
      end

      record.update(captured_output)
      record['time'] = Time.now - @start_time
      record
    end

    #
    def exception_record(example, exception)
      backtrace  = format_backtrace(exception.backtrace || [], example.metadata)
      file, line = split_location(backtrace.first)

      record = {
        'message' => exception.to_s.strip,
        'class'   => exception.class.name
      }
      if file
        record['file'] = file
        record['line'] = line
        add_source(record, file, line)
      end
      record['backtrace'] = backtrace
      record
    end

    # An expectation that wasn't met is a failure, as is a pending
    # example that passed. Anything else raised is an error.
    def failure?(exception)
      return true if Core::Pending::PendingExampleFixedError === exception
      return true if defined?(RSpec::Expectations::ExpectationNotMetError) &&
                     RSpec::Expectations::ExpectationNotMetError === exception
      return true if defined?(RSpec::Mocks::MockExpectationError) &&
                     RSpec::Mocks::MockExpectationError === exception
      false
    end

    # Split `file:line`, with or without more after it, in two.
    def split_location(location)
      md = /\A(.+?):(\d+)(?::|\z)/.match(location.to_s)
      md ? [relative_path(md[1]), md[2].to_i] : [nil, nil]
    end

    # Add the line of source, and the lines around it, to a record.
    def add_source(record, file, line)
      lines = source(file) or return
      record['source']  = lines[line - 1].to_s.strip
      record['snippet'] = snippet(lines, line)
    end

    # The lines of a source file, or nil if it can't be read.
    def source(file)
      return @source_cache[file] if @source_cache.key?(file)
      @source_cache[file] = File.file?(file) ? File.readlines(file) : nil
    end

    # The lines around a line of source, as a list of number => text.
    def snippet(lines, line)
      first = [line - SNIPPET_RADIUS, 1].max
      last  = [line + SNIPPET_RADIUS, lines.size].min
      (first..last).map { |n| { n => lines[n - 1].chomp } }
    end

    # A path under the working directory, written from `./`.
    def relative_path(path)
      directory = File.expand_path('.') + File::SEPARATOR
      path.start_with?(directory) ? './' + path[directory.size..-1] : path
    end

    #
    def format_backtrace(backtrace, metadata)
      configuration.backtrace_formatter.format_backtrace(backtrace, metadata)
    end

    #
    def configuration
      RSpec.configuration
    end

    #
    def capture_output
      release_output
      @real_stdout, @real_stderr = $stdout, $stderr
      @stdout, @stderr = StringIO.new, StringIO.new
      $stdout, $stderr = @stdout, @stderr
    end

    # Put back the real output streams, unless the example changed them
    # itself.
    def release_output
      return unless @stdout
      $stdout = @real_stdout if $stdout.equal?(@stdout)
      $stderr = @real_stderr if $stderr.equal?(@stderr)
      @stdout = @stderr = nil
    end

    # What the example printed, as part of a record.
    def captured_output
      return {} unless @stdout

      stdout = @stdout.string.chomp("\n")
      stderr = @stderr.string.chomp("\n")
      release_output

      record = {}
      record['stdout'] = stdout unless stdout.empty?
      record['stderr'] = stderr unless stderr.empty?
      record
    end

  end

  # Formats in TAP-Y, a stream of YAML documents.
  #
  #     $ rspec -f RSpec::TapY | tapout
  #
  class TapY < TapBaseFormatter
    Core::Formatters.register self, *NOTIFICATIONS

    def initialize(output)
      require 'yaml'
      super
    end

  private

    def emit(record)
      output.puts record.to_yaml
    end

    def finish
      output.puts '...'
    end
  end

  # Formats in TAP-J, a JSON document on each line.
  #
  #     $ rspec -f RSpec::TapJ | tapout
  #
  class TapJ < TapBaseFormatter
    Core::Formatters.register self, *NOTIFICATIONS

    def initialize(output)
      require 'json'
      super
    end

  private

    def emit(record)
      output.puts JSON.generate(record)
    end
  end

end
