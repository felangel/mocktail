import 'package:mocktail/mocktail.dart' as mocktail;

void main() {}

class Mock {}

class NotMocktailMock extends Mock {}

// expect_lint: mocktail_prefer_private_mocks
class PublicMocktailMock extends mocktail.Mock {}

// expect_lint: mocktail_prefer_private_mocks
class PublicSubclassOfMocktailMock extends PublicMocktailMock {}

final PublicSubclassOfMocktailMock mock = PublicSubclassOfMocktailMock();
