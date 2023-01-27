# Mocktail lint examples

Example library that shows lint matches.

Useful for testing the designed lint rules by using `// expect_lint: rule_name` code in the line before our lint:

```dart
// expect_lint: mocktail_prefer_private_mocks
class PublicMocktailMock extends mocktail.Mock {}
```
