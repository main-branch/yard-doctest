# frozen_string_literal: true

require 'rake/clean'

# Load all .rake files from tasks and its subdirectories.
Dir.glob('rake_tasks/**/*.rake').each { |r| load r }

default_tasks = %i[cucumber]

task default: default_tasks

# Prepend a module into Rake::Task to add per-task logging without stomping on
# other patches that may also wrap execute.
module Rake
  # Rake::Task with per-task box logging prepended.
  class Task
    prepend(Module.new do
      def execute(args = nil)
        # Only output the task name if it wasn't the only top-level task
        # rake default      # => output task name for each task called by the default task
        # rake rubocop      # => do not output the task name
        # rake rubocop yard # => output task name for rubocop and yard
        top_level_tasks = Rake.application.top_level_tasks
        box("Rake task: #{name}") unless top_level_tasks.length == 1 && name == top_level_tasks[0]
        super
      end

      private

      def box(message)
        width = message.length + 2
        puts "┌#{'─' * width}┐"
        puts "│ #{message} │"
        puts "└#{'─' * width}┘"
      end
    end)
  end
end
