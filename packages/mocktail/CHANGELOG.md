# 0.0.2-dev.1

- **BREAKING** refactor: removed the `of` parameter of matchers in exchange for a `registerFallbackValue`

# 0.0.2-dev.0

- **BREAKING** refactor: revamp `mocktail` API to be typesafe instead of relying on `Symbol`

# 0.0.1-dev.12

- fix: any matcher with no value

# 0.0.1-dev.11

- chore: bump dependencies
  - `matcher: ^0.12.10`
  - `test: ^1.16.0`

# 0.0.1-dev.10

- feat: `thenReturn` argument is optional for `VoidCallback` returns
  - `when(cat).calls(#makeSound).thenReturn()`
- feat: add support for `captured` with `captureAny` and `captureAnyThat` matchers
- fix: verify fixes for default arguments (named and positional)

# 0.0.1-dev.9

- fix: call verification count per specific real invocation

# 0.0.1-dev.8

- fix: throw `NoSuchMethodError` when arguments match but memberName does not

# 0.0.1-dev.7

- **BREAKING** refactor: rename `verify(mock).calls(#member)` to `verify(mock).called(#member)`
- feat: add `any` argument matcher support to `verify` and `calls`
- feat: add `anyThat` argument matcher support to `verify` and `calls`
- feat: support `verify(mock).called(#member).once()`
- feat: support `verify(mock).called(#member).never()`
- feat: improve error messages to include invocation arguments

# 0.0.1-dev.6

- **BREAKING** refactor: use `Symbol` rather than `String`
- fix: strict argument matching on verification when arguments are provided

# 0.0.1-dev.5

- fix: override `toString` on `MocktailFailure` to improve visibility of failure messages

# 0.0.1-dev.4

- feat: add `Matcher` support to verify times API
- docs: minor usage documentation updates in README

# 0.0.1-dev.3

- **BREAKING** refactor: rename `positionalArgs` to `positionalArguments`
- **BREAKING** refactor: rename `namedArgs` to `namedArguments`
- fix: `thenAnswer` callback contains correct `Invocation`
- docs: minor documentation updates

# 0.0.1-dev.2

- docs: minor updates to README
- docs: minor updates to example

# 0.0.1-dev.1

- feat: initial release 🎉
