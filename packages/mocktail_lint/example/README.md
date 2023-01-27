# Mocktail lint examples

Example library that shows lint matches.

Useful for testing the designed lint rules by using a syntax similar to // ignore, we write a // expect_lint: code in the line before our lint:

```dart
// expect_lint: mocktail_prefer_private_mocks
class PublicMocktailMock extends mocktail.Mock {}
```
