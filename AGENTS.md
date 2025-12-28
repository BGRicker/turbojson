# Repository Guidelines

## Project Structure & Module Organization
This repository targets a Ruby gem named `turbojson` (RapidSerializer/PgJsonBuilder). Use a conventional gem layout:
- `lib/` gem entrypoint and public API (e.g., `lib/turbojson.rb`)
- `lib/turbojson/` core compiler, AST, SQL generator, and DSL
- `spec/` RSpec tests and fixtures
- `bench/` performance benchmarks (e.g., `bench/serialize.rb`)
- `examples/` small Rails demo snippets if needed

## Build, Test, and Development Commands
Document new commands as they land. Expected baseline:
- `bundle exec rspec` run the test suite
- `bundle exec rake` run default tasks (lint/test/bench if configured)
- `bundle exec ruby bench/serialize.rb` run performance checks

## Coding Style & Naming Conventions
Use standard Ruby style (2-space indentation, frozen string literals when appropriate). Prefer:
- class/module names in `CamelCase` under `Turbojson`
- file names in `snake_case` matching constants
- DSL methods: `attributes`, `has_one`, `has_many`
If a formatter is added (e.g., `rubocop`), document the exact command here.

## Architecture & Implementation Notes
The gem compiles serializer DSL definitions into PostgreSQL JSON SQL:
- Phase 1: build an AST that captures source table, columns, and relations
- Phase 2: generate `json_build_object`/`json_agg` SQL from the AST
- Phase 3: enforce strict column validation via schema cache
- Phase 4: handle Active Storage keys and post-process in Ruby for URLs
Prefer `LATERAL JOIN` for `has_many` to avoid correlated subquery hotspots.

## Testing Guidelines
Use RSpec. Focus on:
- correctness vs ActiveModel::Serializer output (keys and structure)
- SQL generation snapshots for nested associations
- performance benchmarks (Benchmark.ips) and memory profiles
Name tests under `spec/` (e.g., `spec/sql_generator_spec.rb`).

## Commit & Pull Request Guidelines
There is no established history yet. Use clear, imperative commits like `Add AST nodes`.
PRs should include:
- a concise description of the DSL or SQL change
- test evidence (`bundle exec rspec`) or a reason for omission
- benchmark notes when changing SQL generation or serialization

## Configuration & Security
Keep secrets out of repo. If Rails example apps are added, use env vars for DB URLs and S3 creds, and document required keys in this file.
