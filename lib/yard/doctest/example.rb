# frozen_string_literal: true

module YARD
  module Doctest
    # Represents a YARD +@example+ tag and generates a Minitest spec from it.
    class Example < ::Minitest::Spec
      # @return [String] namespace path of example (e.g. `Foo#bar`)
      attr_accessor :definition

      # @return [String] filepath to definition (e.g. `app/app.rb:10`)
      attr_accessor :filepath

      # @return [Array<Hash>] assertions to be done
      attr_accessor :asserts

      #
      # Generates a spec and registers it to Minitest runner.
      #
      def generate
        this = self

        Class.new(this.class).class_eval do
          load_helpers
          next if YARD::Doctest.skips.any? { |skip| this.definition.include?(skip) }

          describe this.definition do
            register_hooks(example_name_for(this), YARD::Doctest.hooks, this)
            it(this.name) { run_asserts(this) }
          end
        end
      end

      protected

      def run_asserts(example)
        scope = find_scope(example.definition)
        global_constants, scope_constants = capture_constants(scope)
        example.asserts.each { |assert| run_assert(example, assert, scope) }
        clear_extra_constants(Object, global_constants)
        clear_extra_constants(scope, scope_constants) if scope_constants
      end

      def run_assert(example, assert, scope)
        if assert[:expected].empty?
          evaluate_example(example, assert[:actual], scope)
        else
          assert_example(example, assert[:expected], assert[:actual], scope)
        end
      end

      def find_scope(definition)
        name = definition.split(/#|\./).first
        Object.const_get(name) if name&.match?(/\A[A-Z]/) && Object.const_defined?(name)
      end

      def capture_constants(scope)
        [Object.constants, scope.respond_to?(:constants) ? scope.constants : nil]
      end

      def evaluate_example(example, actual, bind)
        evaluate(actual, bind)
      rescue StandardError => e
        add_filepath_to_backtrace(e, example.filepath)
        raise e
      end

      def assert_example(example, expected, actual, bind)
        expected = evaluate_with_assertion(expected, bind)
        actual = evaluate_with_assertion(actual, bind)
        compare_values(expected, actual)
      rescue Minitest::Assertion => e
        add_filepath_to_backtrace(e, example.filepath)
        raise e
      end

      def compare_values(expected, actual)
        if both_are_errors?(expected, actual)
          assert_equal("#<#{expected.class}: #{expected}>", "#<#{actual.class}: #{actual}>")
        elsif (error = only_one_is_error?(expected, actual))
          raise error
        elsif expected.nil?
          assert_nil(actual)
        else
          assert expected === actual, diff(expected, actual) # rubocop:disable Style/CaseEquality
        end
      end

      def evaluate_with_assertion(code, bind)
        evaluate(code, bind)
      rescue StandardError => e
        e
      end

      def evaluate(code, bind)
        context(bind).eval(code)
      end

      def context(bind)
        @context ||= if bind
                       ctx = bind.class_eval('binding', __FILE__, __LINE__)
                       transplant_instance_variables(ctx)
                       ctx
                     else
                       binding
                     end
      end

      def transplant_instance_variables(ctx)
        # Transplant instance variables from the current binding into ctx so
        # that examples can reference them as if running in the same scope.
        instance_variables.each do |ivar|
          local = "__yard_doctest__#{ivar.to_s.delete('@')}"
          ctx.local_variable_set(local, instance_variable_get(ivar))
          ctx.eval("#{ivar} = #{local}")
        end
      end

      def both_are_errors?(expected, actual)
        expected.is_a?(StandardError) && actual.is_a?(StandardError)
      end

      def only_one_is_error?(expected, actual)
        if expected.is_a?(StandardError) && !actual.is_a?(StandardError)
          expected
        elsif !expected.is_a?(StandardError) && actual.is_a?(StandardError)
          actual
        end
      end

      def add_filepath_to_backtrace(exception, filepath)
        exception.set_backtrace([filepath] + exception.backtrace)
      end

      def clear_extra_constants(scope, constants)
        (scope.constants - constants).each do |constant|
          scope.__send__(:remove_const, constant)
        end
      end

      class << self
        protected

        def load_helpers
          %w[. support spec test].each do |dir|
            require "#{dir}/doctest_helper" if File.exist?("#{dir}/doctest_helper.rb")
          end
        end

        def example_name_for(example)
          return example.definition if example.name.empty?

          "#{example.definition}@#{example.name}"
        end

        # @param [String] example_name The name of the example.
        # @param [Hash<Symbol, Array<Hash<(test: String, block: Proc)>>] all_hooks
        # @param [Example] example
        def register_hooks(example_name, all_hooks, example)
          all_hooks.each do |type, hooks|
            global_hooks = hooks.reject { |hook| hook[:test] }
            test_hooks   = hooks.select { |hook| hook[:test] && example_name.include?(hook[:test]) }
            __send__(type) do
              (global_hooks + test_hooks).each { |hook| instance_exec(example, &hook[:block]) }
            end
          end
        end
      end
    end
  end
end
