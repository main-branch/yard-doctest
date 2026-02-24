# frozen_string_literal: true

module YARD
  module CLI
    # Implements the +yard doctest+ command.
    class Doctest < Command
      def description
        'Doctests from @example tags'
      end

      #
      # Runs the command line, parsing arguments
      # and generating tests.
      #
      # @param [Array<String>] args Switches are passed to minitest,
      #   everything else is treated as the list of directories/files or glob
      #
      def run(*args)
        files = args.grep_v(/^-/)

        files = parse_files(files)
        examples = parse_examples(files)

        add_pwd_to_path

        generate_tests(examples)
        run_tests
      end

      private

      def parse_files(globs)
        globs = %w[app lib] if globs.empty?

        files = globs.map do |glob|
          glob = "#{glob}/**/*.rb" if glob !~ /.rb$/

          Dir[glob]
        end

        files.flatten
      end

      def parse_examples(files)
        YARD.parse(files, excluded_files)
        registry = Registry.load_all
        registry.all.map { |object| object.tags(:example) }.flatten
      end

      def excluded_files
        excluded = []
        args = YARD::Config.with_yardopts { YARD::Config.arguments.dup }
        args.each_with_index do |arg, i|
          next unless arg == '--exclude'

          excluded << args[i + 1]
        end

        excluded
      end

      def generate_tests(examples)
        examples.each do |example|
          build_spec(example).generate
        end
      end

      def build_spec(example)
        YARD::Doctest::Example.new(example.name).tap do |spec|
          spec.definition = example.object.path
          spec.filepath = "#{Dir.pwd}/#{example.object.files.first.join(':')}"
          spec.asserts = parse_example_asserts(example)
        end
      end

      def parse_example_asserts(example)
        lines = lines_from_example_text(example.text)
        [].tap do |arr|
          until lines.empty?
            actual = lines.take_while { |l| l !~ /^#=>/ }
            expected = lines[actual.size] || ''
            lines.slice! 0..actual.size
            arr << { expected: expected.sub('#=>', '').strip, actual: actual.join("\n") }
          end
        end
      end

      def lines_from_example_text(text)
        text = text.gsub('# =>', '#=>')
        text = text.gsub('#=>', "\n#=>")
        text.split("\n").map(&:strip).reject(&:empty?)
      end

      def run_tests
        Minitest.autorun
      end

      def add_pwd_to_path
        $LOAD_PATH.unshift(Dir.pwd) unless $LOAD_PATH.include?(Dir.pwd)
      end
    end
  end
end
