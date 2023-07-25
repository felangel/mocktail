import 'package:example/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail_image_network/mocktail_image_network.dart';

void main() {
  testWidgets('can use mocktail for network images', (tester) async {
    await mockNetworkImages(() async => tester.pumpWidget(const FakeApp()));
    expect(find.byType(Image), findsOneWidget);
  });
}
