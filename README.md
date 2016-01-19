# Happy

the alchemist's [happy path](https://en.wikipedia.org/wiki/Happy_path) with elixir

- [Installation](#installation)
- [About](#about)
- [Usage](#usage)

## Installation

[Available in Hex](https://hex.pm/packages/happy), the package can be installed as:

  1. Add happy to your list of dependencies in `mix.exs`:

```elixir
  def deps do
    [{:happy, "~> 0.0.4"}]
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

###### the `happy` macro

The `happy` macro takes a `do` block and rewrites any first-level pattern matching expression into a `case`.

```elixir
happy do
  {:ok, b} = a
  {:ok, d} = b
  c(d)
end
```

gets rewritten to:

```elixir
case(a) do
  {:ok, b} ->
    case (b) do
      {:ok, d} -> c(d)
    end
end
```

If you want to handle non-matching values,
provide use an `else` block:

```elixir
happy do
  {:ok, b} = a
  c(b)
else
  x -> x
end
```

gets rewritten to:

```elixir
case(a) do
  {:ok, b} -> c(b)
  x -> x
end
```


###### Another example creating a user

```elixir
happy do
  # happy path

  ch = %{valid?: true} = User.changeset(params)
  {:ok, user} = Repo.insert(ch)
  render(conn, "user.json", user: user)

else
  # unhappy path

  invalid = %Changeset{valid?: false} ->
    render(conn, "form.json", changeset: invalid)
  {:error, ch} ->
    text(conn, "could not insert")
  _ ->
    text(conn, "error")
end
```



## Is it any good?

[Yes](https://news.ycombinator.com/item?id=3067434)

