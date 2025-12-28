# turbojson

Compile a Ruby serializer DSL into fast PostgreSQL JSON SQL for read-heavy APIs. Define attributes and associations in Ruby, then generate SQL that returns JSON without instantiating thousands of ActiveRecord objects.

## Why

ActiveRecord is excellent for writes and business logic, but JSON APIs are often read-heavy. Hydrating large object graphs just to serialize them is slow and memory-intensive. `turbojson` lets you keep a familiar serializer DSL while shifting JSON construction to PostgreSQL (`json_build_object`, `json_agg`).

## Install

Add to your Gemfile:

```ruby
gem "turbojson"
```

Or use a local path during development:

```ruby
gem "turbojson", path: "/path/to/turbojson"
```

Then:

```bash
bundle install
```

## Quick Start

Define serializers:

```ruby
class CategorySerializer < Turbojson::Serializer
  model Category
  attributes :id, :name
end

class BarPhotoSerializer < Turbojson::Serializer
  model BarPhoto
  attributes :id, :url
end

class BarSerializer < Turbojson::Serializer
  model Bar
  attributes :id, :name

  has_one :category, serializer: CategorySerializer
  has_many :bar_photos, serializer: BarPhotoSerializer

  attribute :distance do |scope|
    "ST_Distance(#{scope.table_name}.location, 'POINT(...)')"
  end
end
```

Serialize an ActiveRecord scope:

```ruby
scope = Bar.where(active: true).limit(10)
json = BarSerializer.serialize(scope)
```

Generate SQL directly:

```ruby
sql = BarSerializer.to_sql
```

## How It Works

1. DSL definitions build an AST describing the model, attributes, and associations.
2. The SQL generator compiles the AST into `json_build_object` and `json_agg` SQL.
3. `serialize(scope)` wraps the generated SQL around your existing relation to respect `where`, `limit`, and `offset`.
4. The database returns JSON; the gem parses it to Ruby hashes and arrays.

## Strict Column Validation

By default, attributes must be real columns. If a name is not a column, a `Turbojson::ConfigurationError` is raised. Column checks use `schema_cache` when available, then fall back to `columns_hash`.

## Active Storage Key Post-Processing

If you need signed URLs, fetch the key in SQL and post-process in Ruby:

```ruby
payload = BarSerializer.serialize(scope)

signed = Turbojson::PostProcessor.process(payload) do |key|
  blob = ActiveStorage::Blob.find_by!(key: key)
  Rails.application.routes.url_helpers.rails_blob_url(blob, only_path: true)
end
```

## Performance Notes

- Uses `LATERAL` joins for associations to avoid correlated subquery hotspots.
- Avoids instantiating ActiveRecord objects for read-heavy endpoints.

## Testing

Run the test suite:

```bash
bundle exec rspec
```

SQL snapshot tests live under `spec/fixtures/sql/`.

## Roadmap

- Add ActiveModel::Serializer parity specs with a real test database.
- Expand SQL generation to handle advanced filters and custom join strategies.
- Add Benchmark.ips and memory benchmarks under `bench/`.

## Contributing

See `AGENTS.md` for repository guidelines, structure, and development notes.

## License

MIT
