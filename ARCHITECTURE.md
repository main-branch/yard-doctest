# yard-doctest Architecture

## Purpose

yard-doctest is a Ruby gem inspired by Python's `doctest`. It parses `@example` tags
from [YARD](https://yardoc.org/) documentation comments and automatically turns them
into runnable **Minitest specs**.

## Core Flow

1. **Entry point** — The gem registers a `yard doctest` CLI command (see the last
   line of `lib/yard-doctest.rb`: `YARD::CLI::CommandParser.commands[:doctest] =
   YARD::CLI::Doctest`).

2. **Parsing** (`lib/yard/cli/doctest.rb`) — When `yard doctest` runs:
   - It discovers `.rb` files in `app/` and `lib/` (or user-specified paths).
   - Uses **YARD's parser** to load the registry and extract all `@example` tags from
     documented code objects.
   - Parses each example's text into **asserts** by splitting on `#=>` — the left
     side is the code to evaluate, the right side is the expected result.

3. **Test generation** (`lib/yard/doctest/example.rb`) — Each `@example` tag becomes
   an `Example` object (a subclass of `Minitest::Spec`). The `generate` method:
   - Loads a `doctest_helper.rb` file (like `spec_helper.rb` for test setup).
   - Checks against any configured `skip` patterns.
   - Dynamically creates a `describe`/`it` block.
   - Registers `before`/`after` hooks.

4. **Assertion execution** — Inside each test, the example's code is `eval`'d in a
   binding scoped to the relevant class/module. Each `#=>` assertion compares
   expected vs. actual using `===`, with special handling for:
   - `nil` values (`assert_nil`)
   - Exceptions (compares class and message)
   - Constant isolation (cleans up constants defined during a test)

5. **Running** — After all specs are generated, `Minitest.autorun` executes them.

## Configuration (`lib/yard-doctest.rb`)

Users write a `doctest_helper.rb` to configure tests:
- `YARD::Doctest.before { ... }` / `.after { ... }` — hooks (global or per-test)
- `YARD::Doctest.skip('SomeClass#method')` — skip specific examples
- `YARD::Doctest.after_run { ... }` — cleanup after all tests

## Rake Integration (`lib/yard/doctest/rake.rb`)

`YARD::Doctest::RakeTask` provides a Rake task (default name `yard:doctest`) that
shells out to `yard doctest`.

## Example Syntax

In documented Ruby code:
```ruby
# @example Adding numbers
#   1 + 1 #=> 2
```
The `1 + 1` is evaluated, and the result is compared against `2`. Lines without `#=>`
are executed as setup code.

## Testing the Gem Itself

The gem's own tests use **Cucumber/Aruba** (`features/yard-doctest.feature`) to run
integration scenarios that invoke `yard doctest` on sample apps and verify the
expected test output.
