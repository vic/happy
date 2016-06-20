# Happy <a href="https://travis-ci.org/vic/happy"><img src="https://travis-ci.org/vic/happy.svg"></a>

the alchemist's [happy path](https://en.wikipedia.org/wiki/Happy_path) with elixir

- [Installation](#installation)
- [About](#about)
- [Usage](#usage)

## Installation

[Available in Hex](https://hex.pm/packages/happy), the package can be installed as:

  1. Add happy to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [{:happy, "~> 1.2.1"}]
  end
```

## About

Ok, so I was just trying to find a nice way (beautiful syntax, yet flexible enough) to handle
errors in elixir. Handling `:ok`/`:error` like tuples without lots of `if`/`case`s.

After creating [ok_jose](https://github.com/vic/ok_jose), looking at Elixir's [with](http://elixir-lang.org/docs/stable/elixir/Kernel.SpecialForms.html#with/1) special form and other
[alternatives](https://github.com/ruby2elixir/plumber_girl), I wanted to create this tiny library with the
following goals in mind:

- The [happy path](https://en.wikipedia.org/wiki/Happy_path) must be immediately obvious to the eyes.
- Code should not be cluttered and should just work using the elixir you already know.
- Avoid introducing noisy operators `~>>`, requiring commas after each pattern or the counter-intuitive-arrow (to me at least) `pattern <- expr`
- Should provide a way to recover when not so happy moments come.

## Usage

```elixir
import Happy
```

##### the `happy_path` macro

The `happy_path` macro takes a `do` block and rewrites any first-level pattern matching expression into a `case`.

```elixir
happy_path do
  {:ok, b} = a
  {:ok, d} = b
  c(d)
end
```

gets rewritten to something like:

```elixir
case(a) do
  {:ok, b} ->
    case (b) do
      {:ok, d} -> c(d)
    end
end
```

Note that a variable pattern match (assignment) is not
rewritten, as it will always match and would cause warnings.

```elixir
happy_path do
  x = some(thing) # simple assignment is left as is
end
```

###### handling errors with `else` clauses

If you want to handle non-matching values,
provide an `else` block with additional
matching clauses:

```elixir
happy_path do
  {:ok, b} = a
  c(b)
else
  {:error, x} -> x
end
```

###### sharing common error handling code


Sometimes you would want to share common error handling
code on many happy_paths, for example in an api controller 
with many actions, all of which handle common invalid cases
like parameter validation.

In those cases you can provide `happy_path` with an
default error handler as first argument. Note that if no *local
else clause* matches, the error value is *piped* into 
the provided error handler. Thus the handler is anything
you can pipe the error value into.

```elixir
happy_path(else: handler) do 
 {:ok, x} = foo
 x + 1
else
 {:error, y} -> y
end
```

gets rewritten to something like:

```elixir
case foo do
  {:ok, x} -> 
    x + 1
  {:error, y} ->
    y
  err -> 
    err |> handler
end
```

###### support for guards

Just like with `case` you can include guard tests.

```elixir
happy_path do
  x when not is_nil(x) = some(foo)
  x + 1
end
```

###### tags

Tags is an special feature of `happy_path` not found on
alternatives like elixir's `with` expression.

Tags look like module attributes but they are not, they
are just shorthand for tagging a pattern.

```elixir
happy_path do
  # using the `foo` tag
  @foo {:ok, x} = y

  # is exactly the same as
  {:foo, {:ok, x}} = {:foo, y}
else
  {:foo, {:error, e}} -> "Foo error"
end
```

Tags can help error handlers to get a clue about which
context the mismatch was produced on. It's mostly useful
for distingishing between lots of `{:error, _}` like tuples.


##### Example usage in a web application creating a user

```elixir
happy_path do

  %{valid?: true} = ch = User.changeset(params)
  {:ok, user} = Repo.insert(ch)
  render(conn, "user.json", user: user)

else

  %{valid?: false} = ch -> render(conn, "validation_errors.json", ch: ch)
  {:error, ch} -> render(conn, "db_error.json", ch: ch)
  _ -> text(conn, "error")

end
```



## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)

