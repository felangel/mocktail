# 1.0.3

- docs: update ` README.md` to include `any(that: ...)` ([#226](https://github.com/felangel/mocktail/issues/226))
- chore: update LICENSE year
- chore: remove deprecated lint rules

# 1.0.2

- chore(deps): allow pkg:test_api >=0.7.0 ([#220](https://github.com/felangel/mocktail/issues/220))
- docs: update `verify` example in `README.md` ([#215](https://github.com/felangel/mocktail/issues/215))

# 1.0.1

- chore(deps): replace dependency on `package:test` with `package:test_api` to resolve version resolution issues with `pkg:analyzer`, `pkg:test`, and `flutter_test` ([#209](https://github.com/felangel/mocktail/issues/209))
- chore(deps): upgrade to `package:matcher` ^0.12.15

# 1.0.0

- refactor: use more strict analysis options ([#203](https://github.com/felangel/mocktail/issues/203))
- docs: adjust `LICENSE` year
- docs: add topics to `pubspec.yaml`

# 0.3.0

- **BREAKING** feat: add support for type argument matching ([#66](https://github.com/felangel/mocktail/issues/66))
- feat: improve verifyNoMoreInteractions failure message ([#118](https://github.com/felangel/mocktail/issues/118))
- docs: improve argument matcher documentation in `README` ([#102](https://github.com/felangel/mocktail/pull/102))
- docs: fix typo in \_registerMatcher inline docs ([#101](https://github.com/felangel/mocktail/pull/101))
- docs: minor snippet fixes in `README` ([#94](https://github.com/felangel/mocktail/pull/94))
- docs: enhance example to illustrate more use cases

# 0.3.0-dev.1

- **BREAKING** feat: add support for type argument matching ([#66](https://github.com/felangel/mocktail/issues/66))
- docs: minor snippet fixes in `README` ([#94](https://github.com/felangel/mocktail/pull/94))
- docs: enhance example to illustrate more use cases

# 0.2.0

- **BREAKING** refactor: remove generic from `registerFallbackValue`
- docs: add FAQs to README

# 0.1.4

- fix: add built-in fallback for `DateTime`

# 0.1.3

- docs: improve documentation regarding `registerFallbackValue` and how the library works
- tests: add additional tests for asyncVoid stubbing and verification

# 0.1.2

- feat: improve generic fallback support
- feat: improve error message for missing `registerFallbackValue`

# 0.1.1

- fix: add missing fallback value ([#34](https://github.com/felangel/mocktail/pull/34))
- docs: fix broken link in API documentation ([#33](https://github.com/felangel/mocktail/pull/33))

# 0.1.0

- feat: add `Mock.throwOnMissingStub()`
- fix: make `Mock` instances immutable
- chore: convert to `test: ^1.16.0`

# 0.0.2-dev.6

- fix: typo in matcher registration (`setUpAll`)
- chore: upgrade to `test_api: ^0.3.0`

# 0.0.2-dev.5

- fix: `verify` should use arg matcher from invocation if a matcher wasn't provided

# 0.0.2-dev.4

- **BREAKING** fix: `verifyInOrder` handles multiple method invocation verifications
- test: 100% coverage
- docs: additional inline API documentation updates

# 0.0.2-dev.3

- **BREAKING** fix: `verifyInOrder` function signature
- docs: update inline API documentation
- test: add nnbd compat tests

# 0.0.2-dev.2

- chore: documentation updates

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
