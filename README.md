# Happy

the alchemist [happy path](https://en.wikipedia.org/wiki/Happy_path) with elixir

- [Installation](#installation)
- [About](#about)
- [Usage](#usage)

## Installation

[Available in Hex](https://hex.pm/packages/happy), the package can be installed as:

  1. Add happy to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [{:happy, "~> 0.0.2"}]
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
- Avoid introducing noisy operators `~>>`, or counter-intuitive-arrow (to me at least) `pattern <- expr`
- Should provide a way to recover when not so happy moments come.

## Usage

```elixir
import Happy
```

### the `happy` macro

The `happy` macro takes a `do` block and rewrites any first-level pattern matching expression into a `cond`.

```elixir
happy do
  {:ok, b} = a
  {:ok, d} = b
  c(d)
end
```

gets rewritten to:

```elixir
cond do
  {:ok, b} = a ->
    cond do
      {:ok, d} = b -> c(d)
      :else -> :error
    end
  :else -> :error
end
```

The default `:else -> :error` unhappy path can be customized
by an `else` block which must contain additional `cond` clauses like:

```elixir
happy do
  # happy path
  ch = User.changeset(params)
  true = ch.valid?
  {:ok, user} = Repo.insert
  render(conn, "user.json", user: user)
else
  # unhappy path
  {:error, changeset = %Changeset{}} ->
    render(conn, "error.json", changeset: changeset)
  :else ->
    conn |> put_status(500) |> text("error")
end
```



## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)

